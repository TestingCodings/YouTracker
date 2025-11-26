import 'dart:async';

import 'local_storage_service.dart';

/// Service for handling user authentication.
/// This is a stub implementation for future backend integration.
class AuthService {
  static AuthService? _instance;
  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();

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

  /// Initializes the auth service and checks for existing session.
  Future<void> initialize() async {
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

  /// Signs in with Google.
  Future<AuthResult> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Implement actual Google sign-in
    // For now, simulate successful login
    _currentUser = User(
      email: 'user@gmail.com',
      name: 'Google User',
      photoUrl: 'https://ui-avatars.com/api/?name=Google+User',
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

  /// Signs out the current user.
  Future<void> signOut() async {
    // Clear local storage
    final localStorage = LocalStorageService.instance;
    await localStorage.saveSetting(SettingsKeys.isLoggedIn, false);
    await localStorage.deleteSetting(SettingsKeys.userEmail);
    await localStorage.deleteSetting(SettingsKeys.userName);

    _currentUser = null;
    _updateState(AuthState.unauthenticated);
  }

  /// Updates the auth state and notifies listeners.
  void _updateState(AuthState state) {
    _currentState = state;
    _authStateController.add(state);
  }

  /// Disposes of resources.
  void dispose() {
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
