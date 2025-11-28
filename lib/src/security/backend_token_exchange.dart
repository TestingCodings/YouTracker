import 'dart:convert';

import 'package:http/http.dart' as http;

/// Helper class for secure backend token exchange.
///
/// This class provides guidance and helper methods for implementing a secure
/// OAuth token exchange pattern where:
/// 1. Client sends a one-time authorization code to the backend
/// 2. Backend exchanges the code for provider tokens (Google/YouTube)
/// 3. Backend issues a short-lived session token to the client
/// 4. Client uses the session token for authenticated API calls
///
/// ## Security Benefits:
/// - Provider OAuth tokens never touch the client
/// - Short-lived session tokens limit exposure if compromised
/// - Backend can implement additional security measures (rate limiting, IP validation, etc.)
/// - Enables token revocation and session management on the server
///
/// ## Important Notes:
/// - This is a GUIDE implementation - DO NOT include real backend credentials
/// - Your backend should be hosted on HTTPS in production
/// - Implement proper error handling and retry logic
/// - Consider using certificate pinning for additional security
///
/// ## Example Backend Flow:
/// ```
/// Client                                Backend
///   |                                      |
///   |-- 1. OAuth login (get auth code) --> |
///   |                                      |
///   |<--- 2. Auth code response ---------- |
///   |                                      |
///   |-- 3. Exchange code for session ---> |
///   |    POST /auth/exchange               |
///   |    { "code": "...", "provider": "google" }
///   |                                      |-- Exchange with OAuth provider
///   |                                      |<- Get tokens
///   |                                      |-- Store tokens securely
///   |                                      |-- Generate session token
///   |<--- 4. Session token --------------- |
///   |    { "sessionToken": "...",          |
///   |      "expiresAt": "..." }            |
///   |                                      |
/// ```
class BackendTokenExchange {
  /// Base URL for the backend API.
  /// In production, this should be loaded from environment configuration.
  final String baseUrl;

  /// HTTP client for making requests.
  final http.Client _client;

  /// Creates a [BackendTokenExchange] instance.
  ///
  /// [baseUrl] - The base URL of your backend API (e.g., 'https://api.youtracker.example.com')
  /// [client] - Optional HTTP client for testing
  BackendTokenExchange({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Exchanges an OAuth authorization code for a session token.
  ///
  /// [authorizationCode] - The one-time code from OAuth provider
  /// [provider] - The OAuth provider (e.g., 'google', 'youtube')
  /// [codeVerifier] - PKCE code verifier if using PKCE flow
  /// [deviceId] - Optional device identifier for session management
  ///
  /// Returns a [TokenExchangeResult] with session token or error.
  ///
  /// ## Example:
  /// ```dart
  /// final exchange = BackendTokenExchange(baseUrl: Environment.apiBaseUrl);
  /// final result = await exchange.exchangeCodeForSession(
  ///   authorizationCode: authCode,
  ///   provider: 'google',
  /// );
  /// if (result.success) {
  ///   await secureStorage.write(
  ///     key: SecureStorageKeys.sessionToken,
  ///     value: result.sessionToken!,
  ///   );
  /// }
  /// ```
  Future<TokenExchangeResult> exchangeCodeForSession({
    required String authorizationCode,
    required String provider,
    String? codeVerifier,
    String? deviceId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/exchange'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (deviceId != null) 'X-Device-ID': deviceId,
        },
        body: jsonEncode({
          'code': authorizationCode,
          'provider': provider,
          if (codeVerifier != null) 'code_verifier': codeVerifier,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TokenExchangeResult.success(
          sessionToken: data['sessionToken'] as String,
          expiresAt: DateTime.parse(data['expiresAt'] as String),
          userId: data['userId'] as String?,
        );
      } else {
        final error = _parseError(response);
        return TokenExchangeResult.failure(error);
      }
    } catch (e) {
      return TokenExchangeResult.failure(
        'Failed to exchange code: ${e.toString()}',
      );
    }
  }

  /// Refreshes the session token using a valid refresh mechanism.
  ///
  /// [currentSessionToken] - The current session token
  ///
  /// Returns a new [TokenExchangeResult] with refreshed session token.
  Future<TokenExchangeResult> refreshSession({
    required String currentSessionToken,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $currentSessionToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TokenExchangeResult.success(
          sessionToken: data['sessionToken'] as String,
          expiresAt: DateTime.parse(data['expiresAt'] as String),
          userId: data['userId'] as String?,
        );
      } else {
        final error = _parseError(response);
        return TokenExchangeResult.failure(error);
      }
    } catch (e) {
      return TokenExchangeResult.failure(
        'Failed to refresh session: ${e.toString()}',
      );
    }
  }

  /// Revokes the current session (logout).
  ///
  /// [sessionToken] - The session token to revoke
  Future<bool> revokeSession({required String sessionToken}) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/revoke'),
        headers: {
          'Authorization': 'Bearer $sessionToken',
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Parses error message from response.
  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['error'] as String? ??
          data['message'] as String? ??
          'Unknown error (${response.statusCode})';
    } catch (e) {
      return 'Request failed with status ${response.statusCode}';
    }
  }

  /// Disposes of the HTTP client.
  void dispose() {
    _client.close();
  }
}

/// Result of a token exchange operation.
class TokenExchangeResult {
  /// Whether the exchange was successful.
  final bool success;

  /// The session token (if successful).
  final String? sessionToken;

  /// When the session token expires (if successful).
  final DateTime? expiresAt;

  /// The user's ID (if available).
  final String? userId;

  /// Error message (if failed).
  final String? error;

  TokenExchangeResult._({
    required this.success,
    this.sessionToken,
    this.expiresAt,
    this.userId,
    this.error,
  });

  /// Creates a successful result.
  factory TokenExchangeResult.success({
    required String sessionToken,
    required DateTime expiresAt,
    String? userId,
  }) {
    return TokenExchangeResult._(
      success: true,
      sessionToken: sessionToken,
      expiresAt: expiresAt,
      userId: userId,
    );
  }

  /// Creates a failed result.
  factory TokenExchangeResult.failure(String error) {
    return TokenExchangeResult._(
      success: false,
      error: error,
    );
  }
}

/// Documentation for backend implementation.
///
/// Your backend should implement the following endpoints:
///
/// ## POST /auth/exchange
/// Exchange an OAuth authorization code for a session token.
///
/// Request:
/// ```json
/// {
///   "code": "authorization_code_from_oauth",
///   "provider": "google",
///   "code_verifier": "optional_pkce_verifier"
/// }
/// ```
///
/// Response (200 OK):
/// ```json
/// {
///   "sessionToken": "jwt_or_opaque_session_token",
///   "expiresAt": "2024-01-15T10:30:00.000Z",
///   "userId": "user_123"
/// }
/// ```
///
/// ## POST /auth/refresh
/// Refresh an expiring session token.
///
/// Request Headers:
/// - Authorization: Bearer <current_session_token>
///
/// Response (200 OK):
/// ```json
/// {
///   "sessionToken": "new_jwt_or_opaque_session_token",
///   "expiresAt": "2024-01-15T12:30:00.000Z",
///   "userId": "user_123"
/// }
/// ```
///
/// ## POST /auth/revoke
/// Revoke a session token (logout).
///
/// Request Headers:
/// - Authorization: Bearer <session_token>
///
/// Response: 200 OK or 204 No Content
///
/// ## Backend Security Recommendations:
///
/// 1. **Store OAuth tokens securely**: Use encrypted storage (e.g., AWS Secrets Manager,
///    HashiCorp Vault, or encrypted database columns)
///
/// 2. **Implement token rotation**: Regularly rotate refresh tokens
///
/// 3. **Session management**:
///    - Track active sessions per user
///    - Implement "logout all devices" functionality
///    - Set reasonable session durations (e.g., 1 hour)
///
/// 4. **Rate limiting**: Protect exchange and refresh endpoints from abuse
///
/// 5. **Audit logging**: Log all authentication events for security monitoring
///
/// 6. **HTTPS only**: Never accept non-TLS connections
///
/// 7. **Input validation**: Validate all input on the server side
///
/// 8. **Error handling**: Don't expose internal errors; use generic error messages
class _BackendImplementationGuide {
  _BackendImplementationGuide._();
}
