import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../screens/screens.dart';
import '../services/services.dart';
import '../src/ui/pages/sync_status_page.dart';
import '../ui_demo.dart';

/// GoRouter configuration for the app.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Check authentication status
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.state == AuthState.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isUIDemoRoute = state.matchedLocation == '/ui-demo';

      // Allow access to UI demo without authentication
      if (isUIDemoRoute) {
        return null;
      }

      // Redirect to dashboard if logged in and on login page
      if (isLoggedIn && isLoginRoute) {
        return '/dashboard';
      }

      // Redirect to login if not logged in and not on login page
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/comment/:id',
        name: 'commentDetail',
        pageBuilder: (context, state) {
          final commentId = state.pathParameters['id'] ?? '';
          final reduceMotion = MotionSpec.shouldReduceMotion(context);
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: CommentDetailScreen(commentId: commentId),
            transitionDuration: reduceMotion 
                ? Duration.zero 
                : MotionSpec.durationLong,
            reverseTransitionDuration: reduceMotion 
                ? Duration.zero 
                : MotionSpec.durationMedium,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              if (reduceMotion) {
                return child;
              }
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: MotionSpec.curveStandard,
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: MotionSpec.curveStandard,
                  )),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) {
          final reduceMotion = MotionSpec.shouldReduceMotion(context);
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
            transitionDuration: reduceMotion 
                ? Duration.zero 
                : MotionSpec.durationMedium,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              if (reduceMotion) {
                return child;
              }
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: MotionSpec.curveStandard,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/sync-status',
        name: 'syncStatus',
        pageBuilder: (context, state) {
          final reduceMotion = MotionSpec.shouldReduceMotion(context);
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SyncStatusPage(),
            transitionDuration: reduceMotion 
                ? Duration.zero 
                : MotionSpec.durationMedium,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              if (reduceMotion) {
                return child;
              }
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: MotionSpec.curveStandard,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        pageBuilder: (context, state) {
          final reduceMotion = MotionSpec.shouldReduceMotion(context);
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AnalyticsDashboardScreen(),
            transitionDuration: reduceMotion 
                ? Duration.zero 
                : MotionSpec.durationMedium,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              if (reduceMotion) {
                return child;
              }
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: MotionSpec.curveStandard,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/insights',
        name: 'insights',
        pageBuilder: (context, state) {
          final reduceMotion = MotionSpec.shouldReduceMotion(context);
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: const InsightsScreen(),
            transitionDuration: reduceMotion 
                ? Duration.zero 
                : MotionSpec.durationMedium,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              if (reduceMotion) {
                return child;
              }
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: MotionSpec.curveStandard,
                )),
                child: child,
              );
            },
          );
        },
      ),
      // UI Demo page - accessible at /ui-demo
      GoRoute(
        path: '/ui-demo',
        name: 'uiDemo',
        pageBuilder: (context, state) {
          final reduceMotion = MotionSpec.shouldReduceMotion(context);
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: const UIDemoPage(),
            transitionDuration: reduceMotion 
                ? Duration.zero 
                : MotionSpec.durationMedium,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              if (reduceMotion) {
                return child;
              }
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: MotionSpec.curveStandard,
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: MotionSpec.curveStandard,
                    ),
                  ),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      // UI Demo route - available only in debug mode
      if (kDebugMode)
        GoRoute(
          path: '/ui-demo',
          name: 'uiDemo',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const UiDemoPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: child,
                ),
              );
            },
          ),
        ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: AppSpacing.df),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                state.matchedLocation,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

/// Route names for type-safe navigation.
class AppRoutes {
  static const String login = 'login';
  static const String dashboard = 'dashboard';
  static const String commentDetail = 'commentDetail';
  static const String settings = 'settings';
  static const String syncStatus = 'syncStatus';
  static const String analytics = 'analytics';
  static const String insights = 'insights';
  static const String uiDemo = 'uiDemo';
}
