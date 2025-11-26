import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';

/// Provider for interactions.
final interactionsProvider =
    StateNotifierProvider<InteractionsNotifier, InteractionsState>((ref) {
  return InteractionsNotifier();
});

class InteractionsState {
  final List<Interaction> interactions;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  InteractionsState({
    this.interactions = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  InteractionsState copyWith({
    List<Interaction>? interactions,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return InteractionsState(
      interactions: interactions ?? this.interactions,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InteractionsNotifier extends StateNotifier<InteractionsState> {
  InteractionsNotifier() : super(InteractionsState());

  final InteractionApiService _apiService = InteractionApiService();

  /// Fetches all interactions.
  Future<void> fetchInteractions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final interactions = await _apiService.getInteractions();
      final unreadCount = interactions.where((i) => !i.isRead).length;

      state = state.copyWith(
        interactions: interactions,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Marks an interaction as read.
  Future<void> markAsRead(String interactionId) async {
    try {
      final updated = await _apiService.markAsRead(interactionId);
      final updatedList = state.interactions.map((i) {
        if (i.id == interactionId) {
          return updated;
        }
        return i;
      }).toList();

      state = state.copyWith(
        interactions: updatedList,
        unreadCount: updatedList.where((i) => !i.isRead).length,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Marks all interactions as read.
  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllAsRead();
      final updatedList = state.interactions
          .map((i) => i.copyWith(isRead: true))
          .toList();

      state = state.copyWith(
        interactions: updatedList,
        unreadCount: 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Refreshes interactions.
  Future<void> refresh() async {
    await fetchInteractions();
  }
}

/// Provider for interactions of a specific comment.
final commentInteractionsProvider =
    FutureProvider.family<List<Interaction>, String>((ref, commentId) async {
  final apiService = InteractionApiService();
  return apiService.getInteractionsForComment(commentId);
});
