import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../auth/youtube_auth_service.dart';

/// Custom exception for YouTube API errors.
class YouTubeApiException implements Exception {
  final int statusCode;
  final String message;
  final String? reason;
  final bool isRateLimitError;
  final bool isAuthError;
  final bool isRetryable;

  YouTubeApiException({
    required this.statusCode,
    required this.message,
    this.reason,
    this.isRateLimitError = false,
    this.isAuthError = false,
    this.isRetryable = false,
  });

  factory YouTubeApiException.fromResponse(http.Response response) {
    final isRateLimit = response.statusCode == 429 ||
        (response.statusCode == 403 && response.body.contains('quotaExceeded'));
    final isAuthError = response.statusCode == 401;
    final isRetryable = isRateLimit ||
        response.statusCode >= 500 ||
        response.statusCode == 429;

    String message = 'API error';
    String? reason;

    try {
      final body = jsonDecode(response.body);
      if (body['error'] != null) {
        message = body['error']['message'] ?? 'API error';
        if (body['error']['errors'] is List && 
            (body['error']['errors'] as List).isNotEmpty) {
          reason = body['error']['errors'][0]['reason'];
        }
      }
    } catch (e) {
      message = response.reasonPhrase ?? 'Unknown error';
    }

    return YouTubeApiException(
      statusCode: response.statusCode,
      message: message,
      reason: reason,
      isRateLimitError: isRateLimit,
      isAuthError: isAuthError,
      isRetryable: isRetryable,
    );
  }

  @override
  String toString() => 'YouTubeApiException($statusCode): $message${reason != null ? ' ($reason)' : ''}';
}

/// Configuration for retry behavior.
class RetryConfig {
  /// Maximum number of retry attempts.
  final int maxRetries;
  
  /// Initial delay before first retry.
  final Duration initialDelay;
  
  /// Maximum delay between retries.
  final Duration maxDelay;
  
  /// Multiplier for exponential backoff.
  final double backoffMultiplier;

  /// Random instance for jitter calculation.
  static final Random _random = Random();

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 32),
    this.backoffMultiplier = 2.0,
  });

  /// Calculates delay for a given retry attempt.
  Duration getDelayForAttempt(int attempt) {
    final delay = initialDelay.inMilliseconds * 
        pow(backoffMultiplier, attempt).toInt();
    final cappedDelay = min(delay, maxDelay.inMilliseconds);
    // Add jitter (±25% of delay) to prevent thundering herd
    final jitter = (cappedDelay * 0.25 * (_random.nextDouble() * 2 - 1)).toInt();
    return Duration(milliseconds: cappedDelay + jitter);
  }
}

/// HTTP client for YouTube Data API v3 with automatic token refresh,
/// rate-limit handling, and exponential backoff.
class YouTubeApiClient {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  
  final YouTubeAuthService _authService;
  final http.Client _httpClient;
  final RetryConfig _retryConfig;

  YouTubeApiClient({
    required YouTubeAuthService authService,
    http.Client? httpClient,
    RetryConfig? retryConfig,
  })  : _authService = authService,
        _httpClient = httpClient ?? http.Client(),
        _retryConfig = retryConfig ?? const RetryConfig();

  /// Makes a GET request to the YouTube API with automatic retry.
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    return _makeRequestWithRetry(() async {
      final uri = _buildUri(endpoint, queryParameters);
      final headers = await _getHeaders();
      
      if (headers == null) {
        throw YouTubeApiException(
          statusCode: 401,
          message: 'Not authenticated',
          isAuthError: true,
        );
      }

      final response = await _httpClient.get(uri, headers: headers);
      return _handleResponse(response);
    });
  }

  /// Makes a POST request to the YouTube API with automatic retry.
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    return _makeRequestWithRetry(() async {
      final uri = _buildUri(endpoint, queryParameters);
      final headers = await _getHeaders();
      
      if (headers == null) {
        throw YouTubeApiException(
          statusCode: 401,
          message: 'Not authenticated',
          isAuthError: true,
        );
      }

      final requestHeaders = {
        ...headers,
        'Content-Type': 'application/json',
      };

      final response = await _httpClient.post(
        uri,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    });
  }

  /// Makes a DELETE request to the YouTube API with automatic retry.
  Future<void> delete(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    await _makeRequestWithRetry(() async {
      final uri = _buildUri(endpoint, queryParameters);
      final headers = await _getHeaders();
      
      if (headers == null) {
        throw YouTubeApiException(
          statusCode: 401,
          message: 'Not authenticated',
          isAuthError: true,
        );
      }

      final response = await _httpClient.delete(uri, headers: headers);
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw YouTubeApiException.fromResponse(response);
      }
      
      return <String, dynamic>{};
    });
  }

  /// Builds the full URI for an API endpoint.
  Uri _buildUri(String endpoint, Map<String, String>? queryParameters) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParameters,
    );
  }

  /// Gets authentication headers, refreshing token if needed.
  Future<Map<String, String>?> _getHeaders() async {
    return await _authService.getAuthHeaders();
  }

  /// Handles the HTTP response, parsing JSON or throwing errors.
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    
    throw YouTubeApiException.fromResponse(response);
  }

  /// Makes a request with automatic retry for transient errors.
  Future<T> _makeRequestWithRetry<T>(Future<T> Function() request) async {
    int attempt = 0;
    
    while (true) {
      try {
        return await request();
      } on YouTubeApiException catch (e) {
        if (e.isAuthError) {
          // Try to refresh token once
          if (attempt == 0) {
            final newToken = await _authService.refreshToken();
            if (newToken != null) {
              attempt++;
              continue;
            }
          }
          rethrow;
        }

        if (!e.isRetryable || attempt >= _retryConfig.maxRetries) {
          rethrow;
        }

        final delay = _retryConfig.getDelayForAttempt(attempt);
        await Future.delayed(delay);
        attempt++;
      } on SocketException catch (e) {
        // Network error - retry
        if (attempt >= _retryConfig.maxRetries) {
          throw YouTubeApiException(
            statusCode: 0,
            message: 'Network error: ${e.message}',
            isRetryable: false,
          );
        }

        final delay = _retryConfig.getDelayForAttempt(attempt);
        await Future.delayed(delay);
        attempt++;
      } on TimeoutException catch (e) {
        // Timeout - retry
        if (attempt >= _retryConfig.maxRetries) {
          throw YouTubeApiException(
            statusCode: 0,
            message: 'Request timeout: ${e.message}',
            isRetryable: false,
          );
        }

        final delay = _retryConfig.getDelayForAttempt(attempt);
        await Future.delayed(delay);
        attempt++;
      }
    }
  }

  /// Closes the HTTP client.
  void close() {
    _httpClient.close();
  }
}
