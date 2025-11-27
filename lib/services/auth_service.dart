import 'dart:async';

import 'auth/youtube_auth_service.dart';
import 'auth/token_storage.dart';
import 'local_storage_service.dart';

/// Service for handling user authentication.
/// Supports both legacy authentication and YouTube OAuth.
class AuthService {
  static AuthService? _instance;
  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();

  /// Factory constructor for testing/custom configuration.
  factory AuthService.withYouTubeAuth({
    required YouTubeAuthService youtubeAuthService,
  }) {
    return AuthService._withYouTube(youtubeAuthService);
  }

  AuthService._withYouTube(this._youtubeAuthService);

  YouTubeAuthService? _youtubeAuthService;

  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  /// Stream of authentication state changes.
  Stream<AuthState> get authStateStream => _authStateController.stream;

  /// Current authentication state.
  AuthState _currentState = AuthState.unknown;
  AuthState get currentState => _currentState;

  /// Current user information.
  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Whether using YouTube authentication.
  bool get isUsingYouTubeAuth => _youtubeAuthService != null;

  /// Gets the YouTube auth service (initializing if needed).
  YouTubeAuthService get youtubeAuthService {
    _youtubeAuthService ??= YouTubeAuthService();
    return _youtubeAuthService!;
  }

  /// Initializes the auth service and checks for existing session.
  Future<void> initialize() async {
    // Try YouTube auth first if available
    if (_youtubeAuthService != null) {
      await _youtubeAuthService!.initialize();
      
      if (_youtubeAuthService!.isAuthenticated) {
        final ytUser = _youtubeAuthService!.currentUser;
        if (ytUser != null) {
          _currentUser = User(
            email: ytUser.email,
            name: ytUser.displayName,
            photoUrl: ytUser.photoUrl,
          );
          _updateState(AuthState.authenticated);
          return;
        }
      }
    }

    // Fall back to local storage check
    final localStorage = LocalStorageService.instance;
    final isLoggedIn =
        localStorage.getSettingWithDefault<bool>(SettingsKeys.isLoggedIn, false);

    if (isLoggedIn) {
      _currentUser = User(
        email:
            localStorage.getSetting<String>(SettingsKeys.userEmail) ?? '',
        name:
            localStorage.getSetting<String>(SettingsKeys.userName) ?? 'User',
      );
      _updateState(AuthState.authenticated);
    } else {
      _updateState(AuthState.unauthenticated);
    }
  }

  /// Signs in with email and password.
  /// Returns true if successful, false otherwise.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Implement actual authentication
    // For now, accept any non-empty credentials
    if (email.isEmpty || password.isEmpty) {
      return AuthResult(
        success: false,
        message: 'Email and password are required',
      );
    }

    // Mock validation - in production, this would call the backend
    if (!email.contains('@')) {
      return AuthResult(
        success: false,
        message: 'Please enter a valid email address',
      );
    }

    if (password.length < 6) {
      return AuthResult(
        success: false,
        message: 'Password must be at least 6 characters',
      );
    }

    // Simulate successful login
    _currentUser = User(
      email: email,
      name: email.split('@').first,
    );

    // Save to local storage
    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(SettingsKeys.isLoggedIn, true);
    await localStorage.saveSetting(SettingsKeys.userEmail, email);
    await localStorage.saveSetting(SettingsKeys.userName, _currentUser!.name);

    _updateState(AuthState.authenticated);

    return AuthResult(
      success: true,
      message: 'Login successful',
      user: _currentUser,
    );
  }

  /// Signs in with Google/YouTube.
  Future<AuthResult> signInWithGoogle() async {
    final result = await youtubeAuthService.signIn();

    if (result.success && result.user != null) {
      _currentUser = User(
        email: result.user!.email,
        name: result.user!.displayName,
        photoUrl: result.user!.photoUrl,
      );

      // Save to local storage
      final localStorage = LocalStorageService.instance;
      await localStorage.saveSetting(SettingsKeys.isLoggedIn, true);
      await localStorage.saveSetting(SettingsKeys.userEmail, _currentUser!.email);
      await localStorage.saveSetting(SettingsKeys.userName, _currentUser!.name);

      _updateState(AuthState.authenticated);

      return AuthResult(
        success: true,
        message: 'Google sign-in successful',
        user: _currentUser,
      );
    }

    return AuthResult(
      success: false,
      message: result.message ?? 'Google sign-in failed',
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    // Sign out from YouTube if using it
    if (_youtubeAuthService != null) {
      await _youtubeAuthService!.signOut();
    }

    // Clear local storage
    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(SettingsKeys.isLoggedIn, false);
    await localStorage.deleteSetting(SettingsKeys.userEmail);
    await localStorage.deleteSetting(SettingsKeys.userName);

    _currentUser = null;
    _updateState(AuthState.unauthenticated);
  }

  /// Disconnects the Google account (revokes permissions).
  Future<void> disconnect() async {
    if (_youtubeAuthService != null) {
      await _youtubeAuthService!.disconnect();
    }
    await signOut();
  }

  /// Gets a valid access token for YouTube API calls.
  Future<String?> getAccessToken() async {
    if (_youtubeAuthService == null) return null;
    return await _youtubeAuthService!.getValidAccessToken();
  }

  /// Gets authentication headers for API calls.
  Future<Map<String, String>?> getAuthHeaders() async {
    if (_youtubeAuthService == null) return null;
    return await _youtubeAuthService!.getAuthHeaders();
  }

  /// Updates the auth state and notifies listeners.
  void _updateState(AuthState state) {
    _currentState = state;
    _authStateController.add(state);
  }

  /// Disposes of resources.
  void dispose() {
    _youtubeAuthService?.dispose();
    _authStateController.close();
  }
}

/// Enum representing the current authentication state.
enum AuthState {
  unknown,
  authenticated,
  unauthenticated,
}

/// Result of an authentication operation.
class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

/// User model for authentication.
class User {
  final String email;
  final String name;
  final String? photoUrl;

  User({
    required this.email,
    required this.name,
    this.photoUrl,
  });
}
