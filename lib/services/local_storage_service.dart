import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';

/// Service for managing local storage using Hive.
class LocalStorageService {
  static const String _commentsBoxName = 'comments';
  static const String _interactionsBoxName = 'interactions';
  static const String _settingsBoxName = 'settings';

  static LocalStorageService? _instance;
  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  LocalStorageService._();

  late Box<Comment> _commentsBox;
  late Box<Interaction> _interactionsBox;
  late Box<dynamic> _settingsBox;

  bool _isInitialized = false;

  /// Initializes Hive and opens all required boxes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CommentAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(InteractionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(InteractionAdapter());
    }

    // Open boxes
    _commentsBox = await Hive.openBox<Comment>(_commentsBoxName);
    _interactionsBox = await Hive.openBox<Interaction>(_interactionsBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

    _isInitialized = true;
  }

  // ============ Comments ============

  /// Saves a comment to local storage.
  Future<void> saveComment(Comment comment) async {
    await _commentsBox.put(comment.id, comment);
  }

  /// Saves multiple comments to local storage.
  Future<void> saveComments(List<Comment> comments) async {
    final Map<String, Comment> commentsMap = {
      for (var c in comments) c.id: c,
    };
    await _commentsBox.putAll(commentsMap);
  }

  /// Gets a comment by ID from local storage.
  Comment? getComment(String id) {
    return _commentsBox.get(id);
  }

  /// Gets all comments from local storage.
  List<Comment> getAllComments() {
    return _commentsBox.values.toList();
  }

  /// Deletes a comment from local storage.
  Future<void> deleteComment(String id) async {
    await _commentsBox.delete(id);
  }

  /// Clears all comments from local storage.
  Future<void> clearComments() async {
    await _commentsBox.clear();
  }

  // ============ Interactions ============

  /// Saves an interaction to local storage.
  Future<void> saveInteraction(Interaction interaction) async {
    await _interactionsBox.put(interaction.id, interaction);
  }

  /// Saves multiple interactions to local storage.
  Future<void> saveInteractions(List<Interaction> interactions) async {
    final Map<String, Interaction> interactionsMap = {
      for (var i in interactions) i.id: i,
    };
    await _interactionsBox.putAll(interactionsMap);
  }

  /// Gets an interaction by ID from local storage.
  Interaction? getInteraction(String id) {
    return _interactionsBox.get(id);
  }

  /// Gets all interactions from local storage.
  List<Interaction> getAllInteractions() {
    return _interactionsBox.values.toList();
  }

  /// Deletes an interaction from local storage.
  Future<void> deleteInteraction(String id) async {
    await _interactionsBox.delete(id);
  }

  /// Clears all interactions from local storage.
  Future<void> clearInteractions() async {
    await _interactionsBox.clear();
  }

  // ============ Settings ============

  /// Saves a setting value.
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  /// Gets a setting value.
  T? getSetting<T>(String key) {
    return _settingsBox.get(key) as T?;
  }

  /// Gets a setting value with a default.
  T getSettingWithDefault<T>(String key, T defaultValue) {
    return (_settingsBox.get(key) as T?) ?? defaultValue;
  }

  /// Deletes a setting.
  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }

  /// Clears all settings.
  Future<void> clearSettings() async {
    await _settingsBox.clear();
  }

  // ============ Utility ============

  /// Clears all data from local storage.
  Future<void> clearAll() async {
    await _commentsBox.clear();
    await _interactionsBox.clear();
    await _settingsBox.clear();
  }

  /// Closes all boxes.
  Future<void> close() async {
    await _commentsBox.close();
    await _interactionsBox.close();
    await _settingsBox.close();
  }
}

/// Settings keys for local storage.
class SettingsKeys {
  static const String isDarkMode = 'isDarkMode';
  static const String notificationsEnabled = 'notificationsEnabled';
  static const String syncEnabled = 'syncEnabled';
  static const String syncInterval = 'syncInterval';
  static const String lastSyncTime = 'lastSyncTime';
  static const String isLoggedIn = 'isLoggedIn';
  static const String userEmail = 'userEmail';
  static const String userName = 'userName';
}
