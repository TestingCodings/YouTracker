import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

import 'token_storage.dart';

/// YouTube OAuth scopes required for the app.
class YouTubeScopes {
  /// Read-only access to YouTube account data.
  static const String youtubeReadonly = 'https://www.googleapis.com/auth/youtube.readonly';
  
  /// Full access to manage YouTube account.
  static const String youtube = 'https://www.googleapis.com/auth/youtube';
  
  /// Access to force SSL for all YouTube Data API calls.
  static const String youtubeForceSsl = 'https://www.googleapis.com/auth/youtube.force-ssl';

  /// Default scopes for the app - read-only for fetching comments.
  static const List<String> defaultScopes = [
    youtubeReadonly,
    youtubeForceSsl,
  ];

  /// All available scopes including write access.
  static const List<String> allScopes = [
    youtubeReadonly,
    youtube,
    youtubeForceSsl,
  ];
}

/// Result of an authentication operation.
class YouTubeAuthResult {
  final bool success;
  final String? message;
  final YouTubeUser? user;
  final String? accessToken;
  final DateTime? tokenExpiry;

  YouTubeAuthResult({
    required this.success,
    this.message,
    this.user,
    this.accessToken,
    this.tokenExpiry,
  });

  factory YouTubeAuthResult.success({
    required YouTubeUser user,
    required String accessToken,
    required DateTime tokenExpiry,
  }) {
    return YouTubeAuthResult(
      success: true,
      user: user,
      accessToken: accessToken,
      tokenExpiry: tokenExpiry,
    );
  }

  factory YouTubeAuthResult.failure(String message) {
    return YouTubeAuthResult(
      success: false,
      message: message,
    );
  }
}

/// Represents an authenticated YouTube user.
class YouTubeUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  YouTubeUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  factory YouTubeUser.fromGoogleSignInAccount(GoogleSignInAccount account) {
    return YouTubeUser(
      id: account.id,
      email: account.email,
      displayName: account.displayName ?? account.email.split('@').first,
      photoUrl: account.photoUrl,
    );
  }
}

/// Authentication state for the YouTube service.
enum YouTubeAuthState {
  /// Authentication state is not yet determined.
  unknown,
  /// User is authenticated with valid tokens.
  authenticated,
  /// User is not authenticated.
  unauthenticated,
  /// Authentication is in progress.
  authenticating,
  /// Token is being refreshed.
  refreshing,
}

/// Service for handling YouTube OAuth2 authentication.
/// Uses Google Sign-In to obtain OAuth tokens with YouTube scopes.
class YouTubeAuthService {
  final TokenStorage _tokenStorage;
  final GoogleSignIn _googleSignIn;
  
  final StreamController<YouTubeAuthState> _authStateController =
      StreamController<YouTubeAuthState>.broadcast();

  YouTubeAuthState _currentState = YouTubeAuthState.unknown;
  YouTubeUser? _currentUser;

  YouTubeAuthService({
    TokenStorage? tokenStorage,
    GoogleSignIn? googleSignIn,
    List<String> scopes = YouTubeScopes.defaultScopes,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          scopes: scopes,
          // Force account selection to ensure proper auth flow
          forceCodeForRefreshToken: true,
        );

  /// Stream of authentication state changes.
  Stream<YouTubeAuthState> get authStateStream => _authStateController.stream;

  /// Current authentication state.
  YouTubeAuthState get currentState => _currentState;

  /// Current authenticated user.
  YouTubeUser? get currentUser => _currentUser;

  /// Checks if the user is authenticated.
  bool get isAuthenticated => _currentState == YouTubeAuthState.authenticated;

  /// Initializes the auth service and attempts silent sign-in.
  Future<void> initialize() async {
    _updateState(YouTubeAuthState.unknown);

    // Check for existing tokens
    final hasValidTokens = await _tokenStorage.hasValidTokens();
    
    if (hasValidTokens) {
      // Try to restore user from stored data
      final storedData = await _tokenStorage.getStoredTokenData();
      if (storedData != null && storedData.userId != null) {
        _currentUser = YouTubeUser(
          id: storedData.userId!,
          email: storedData.email ?? '',
          displayName: storedData.name ?? 'User',
          photoUrl: storedData.photoUrl,
        );
        _updateState(YouTubeAuthState.authenticated);
        return;
      }
    }

    // Try silent sign-in
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        await _handleSuccessfulSignIn(account);
        return;
      }
    } catch (e) {
      // Silent sign-in failed, user needs to sign in interactively
    }

    _updateState(YouTubeAuthState.unauthenticated);
  }

  /// Signs in with Google, requesting YouTube scopes.
  Future<YouTubeAuthResult> signIn() async {
    _updateState(YouTubeAuthState.authenticating);

    try {
      final account = await _googleSignIn.signIn();
      
      if (account == null) {
        _updateState(YouTubeAuthState.unauthenticated);
        return YouTubeAuthResult.failure('Sign-in was cancelled');
      }

      return await _handleSuccessfulSignIn(account);
    } catch (e) {
      _updateState(YouTubeAuthState.unauthenticated);
      return YouTubeAuthResult.failure('Sign-in failed: ${e.toString()}');
    }
  }

  /// Handles successful sign-in by storing tokens and user info.
  Future<YouTubeAuthResult> _handleSuccessfulSignIn(GoogleSignInAccount account) async {
    try {
      final auth = await account.authentication;
      
      if (auth.accessToken == null) {
        _updateState(YouTubeAuthState.unauthenticated);
        return YouTubeAuthResult.failure('Failed to obtain access token');
      }

      // Calculate token expiry (Google access tokens typically expire in 1 hour)
      final tokenExpiry = DateTime.now().add(const Duration(hours: 1));

      // Store tokens
      await _tokenStorage.saveTokens(
        accessToken: auth.accessToken!,
        refreshToken: auth.idToken, // Note: Google Sign-In doesn't provide refresh token directly
        expiry: tokenExpiry,
        scopes: YouTubeScopes.defaultScopes,
      );

      // Store user info
      await _tokenStorage.saveUserInfo(
        userId: account.id,
        email: account.email,
        name: account.displayName ?? account.email.split('@').first,
        photoUrl: account.photoUrl,
      );

      _currentUser = YouTubeUser.fromGoogleSignInAccount(account);
      _updateState(YouTubeAuthState.authenticated);

      return YouTubeAuthResult.success(
        user: _currentUser!,
        accessToken: auth.accessToken!,
        tokenExpiry: tokenExpiry,
      );
    } catch (e) {
      _updateState(YouTubeAuthState.unauthenticated);
      return YouTubeAuthResult.failure('Failed to process authentication: ${e.toString()}');
    }
  }

  /// Gets a valid access token, refreshing if necessary.
  /// Returns null if refresh fails and user needs to re-authenticate.
  Future<String?> getValidAccessToken() async {
    final isExpired = await _tokenStorage.isTokenExpired();
    
    if (!isExpired) {
      return await _tokenStorage.getAccessToken();
    }

    // Token is expired, try to refresh
    return await refreshToken();
  }

  /// Refreshes the access token using silent sign-in.
  /// Returns the new access token or null if refresh fails.
  Future<String?> refreshToken() async {
    _updateState(YouTubeAuthState.refreshing);

    try {
      // Try silent sign-in to get new tokens
      final account = await _googleSignIn.signInSilently(reAuthenticate: true);
      
      if (account == null) {
        // Silent sign-in failed, user needs to sign in interactively
        _updateState(YouTubeAuthState.unauthenticated);
        return null;
      }

      final auth = await account.authentication;
      
      if (auth.accessToken == null) {
        _updateState(YouTubeAuthState.unauthenticated);
        return null;
      }

      // Update stored token
      final tokenExpiry = DateTime.now().add(const Duration(hours: 1));
      await _tokenStorage.updateAccessToken(
        accessToken: auth.accessToken!,
        expiry: tokenExpiry,
      );

      _updateState(YouTubeAuthState.authenticated);
      return auth.accessToken;
    } catch (e) {
      _updateState(YouTubeAuthState.unauthenticated);
      return null;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _tokenStorage.clearAll();
    _currentUser = null;
    _updateState(YouTubeAuthState.unauthenticated);
  }

  /// Disconnects the app from the user's Google account.
  /// This revokes all permissions granted to the app.
  Future<void> disconnect() async {
    await _googleSignIn.disconnect();
    await _tokenStorage.clearAll();
    _currentUser = null;
    _updateState(YouTubeAuthState.unauthenticated);
  }

  /// Gets the authentication headers for API requests.
  Future<Map<String, String>?> getAuthHeaders() async {
    final accessToken = await getValidAccessToken();
    if (accessToken == null) return null;
    
    return {
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    };
  }

  /// Updates the auth state and notifies listeners.
  void _updateState(YouTubeAuthState state) {
    _currentState = state;
    _authStateController.add(state);
  }

  /// Disposes of resources.
  void dispose() {
    _authStateController.close();
  }
}
