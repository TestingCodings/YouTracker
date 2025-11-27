import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';
import 'routes/app_router.dart';
import 'services/services.dart';
import 'src/sync/sync_engine.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage
  await LocalStorageService.instance.initialize();

  // Initialize sync engine (offline-first architecture)
  await SyncEngine.instance.initialize();

  // Initialize notification service (stub)
  await NotificationService.instance.initialize();

  // Initialize background sync service (stub)
  await BackgroundSyncService.instance.initialize();

  runApp(
    const ProviderScope(
      child: YouTrackerApp(),
    ),
  );
}

/// Main application widget.
class YouTrackerApp extends ConsumerStatefulWidget {
  const YouTrackerApp({super.key});

  @override
  ConsumerState<YouTrackerApp> createState() => _YouTrackerAppState();
}

class _YouTrackerAppState extends ConsumerState<YouTrackerApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize auth state
    await ref.read(authStateProvider.notifier).initialize();

    // Initialize theme
    await ref.read(themeModeProvider.notifier).initialize();

    // Initialize settings
    await ref.read(settingsProvider.notifier).initialize();

    // Start background sync if enabled
    final settings = ref.read(settingsProvider);
    if (settings.syncEnabled) {
      SyncEngine.instance.startBackgroundSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'YouTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
