import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';

/// Provider for the authentication state.
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthStateData>((ref) {
  return AuthStateNotifier();
});

class AuthStateData {
  final AuthState state;
  final User? user;
  final bool isLoading;
  final String? error;

  AuthStateData({
    this.state = AuthState.unknown,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthStateData copyWith({
    AuthState? state,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthStateData> {
  AuthStateNotifier() : super(AuthStateData());

  final AuthService _authService = AuthService.instance;

  Future<void> initialize() async {
    await _authService.initialize();
    state = state.copyWith(
      state: _authService.currentState,
      user: _authService.currentUser,
    );
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authService.signIn(
      email: email,
      password: password,
    );

    if (result.success) {
      state = state.copyWith(
        state: AuthState.authenticated,
        user: result.user,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.message,
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authService.signInWithGoogle();

    if (result.success) {
      state = state.copyWith(
        state: AuthState.authenticated,
        user: result.user,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.message,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthStateData(state: AuthState.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
