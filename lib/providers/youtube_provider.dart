import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';

/// Provider for token storage service.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

/// Provider for YouTube auth service.
final youtubeAuthServiceProvider = Provider<YouTubeAuthService>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return YouTubeAuthService(tokenStorage: tokenStorage);
});

/// Provider for YouTube auth state.
final youtubeAuthStateProvider =
    StateNotifierProvider<YouTubeAuthStateNotifier, YouTubeAuthStateData>((ref) {
  final authService = ref.watch(youtubeAuthServiceProvider);
  return YouTubeAuthStateNotifier(authService);
});

/// Data class for YouTube auth state.
class YouTubeAuthStateData {
  final YouTubeAuthState state;
  final YouTubeUser? user;
  final bool isLoading;
  final String? error;

  YouTubeAuthStateData({
    this.state = YouTubeAuthState.unknown,
    this.user,
    this.isLoading = false,
    this.error,
  });

  YouTubeAuthStateData copyWith({
    YouTubeAuthState? state,
    YouTubeUser? user,
    bool? isLoading,
    String? error,
  }) {
    return YouTubeAuthStateData(
      state: state ?? this.state,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => state == YouTubeAuthState.authenticated;
}

/// State notifier for YouTube auth state.
class YouTubeAuthStateNotifier extends StateNotifier<YouTubeAuthStateData> {
  final YouTubeAuthService _authService;

  YouTubeAuthStateNotifier(this._authService) : super(YouTubeAuthStateData()) {
    // Listen to auth state changes
    _authService.authStateStream.listen((authState) {
      state = state.copyWith(
        state: authState,
        user: _authService.currentUser,
      );
    });
  }

  /// Initializes the YouTube auth service.
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.initialize();
      state = state.copyWith(
        state: _authService.currentState,
        user: _authService.currentUser,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Signs in with Google/YouTube.
  Future<bool> signIn() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authService.signIn();

    if (result.success) {
      state = state.copyWith(
        state: YouTubeAuthState.authenticated,
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

  /// Signs out from YouTube.
  Future<void> signOut() async {
    await _authService.signOut();
    state = YouTubeAuthStateData(state: YouTubeAuthState.unauthenticated);
  }

  /// Disconnects the Google account.
  Future<void> disconnect() async {
    await _authService.disconnect();
    state = YouTubeAuthStateData(state: YouTubeAuthState.unauthenticated);
  }

  /// Clears any error.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for YouTube API client.
final youtubeApiClientProvider = Provider<YouTubeApiClient>((ref) {
  final authService = ref.watch(youtubeAuthServiceProvider);
  return YouTubeApiClient(authService: authService);
});

/// Provider for YouTube data service.
final youtubeDataServiceProvider = Provider<YouTubeDataService>((ref) {
  final apiClient = ref.watch(youtubeApiClientProvider);
  return YouTubeDataService(apiClient: apiClient);
});

/// Provider for CommentApiService that uses YouTube API when authenticated.
final commentApiServiceProvider = Provider<CommentApiService>((ref) {
  final youtubeAuthState = ref.watch(youtubeAuthStateProvider);
  
  if (youtubeAuthState.isAuthenticated) {
    final youtubeDataService = ref.watch(youtubeDataServiceProvider);
    return CommentApiService(
      youtubeDataService: youtubeDataService,
      useMockData: false,
    );
  }
  
  // Fall back to mock data when not authenticated
  return CommentApiService(useMockData: true);
});

/// Provider for the user's YouTube channel.
final myChannelProvider = FutureProvider<YouTubeChannel?>((ref) async {
  final youtubeAuthState = ref.watch(youtubeAuthStateProvider);
  
  if (!youtubeAuthState.isAuthenticated) {
    return null;
  }
  
  final dataService = ref.watch(youtubeDataServiceProvider);
  return dataService.getMyChannel();
});

/// Provider for sync state.
final syncStateProvider = Provider<SyncState>((ref) {
  final commentApiService = ref.watch(commentApiServiceProvider);
  return commentApiService.syncState ?? SyncState();
});
