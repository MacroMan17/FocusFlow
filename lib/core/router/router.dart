import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/providers.dart';
import '../../presentation/screens/calendar/calendar_screen.dart';
import '../services/notification_service.dart';
import '../../presentation/screens/category/categories_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/settings/appearance_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/statistics/statistics_screen.dart';
import '../../presentation/screens/task/add_edit_task_screen.dart';
import '../../presentation/screens/task/task_detail_screen.dart';
import '../shell/main_shell.dart'; // lib/core/shell/main_shell.dart

// ── Route name constants ───────────────────────────────────────────────────
class RouteNames {
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const home = 'home';
  static const taskAdd = 'task-add';
  static const taskDetail = 'task-detail';
  static const taskEdit = 'task-edit';
  static const categories = 'categories';
  static const search = 'search';
  static const calendar = 'calendar';
  static const statistics = 'statistics';
  static const settings = 'settings';
  static const appearance = 'appearance';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  // Reacts to settings changes (onboardingCompleted flag).
  final settingsAsync = ref.watch(settingsNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // ── Notification deep-link ──────────────────────────────────────────
      final payload = NotificationService.pendingNavigationPayload;
      if (payload != null && payload.isNotEmpty) {
        NotificationService.pendingNavigationPayload = null;
        return '/task/$payload';
      }

      // ── Onboarding guard ────────────────────────────────────────────────
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // While settings are still loading keep the user on splash.
      final isLoading = settingsAsync.isLoading;
      if (isLoading) return isSplash ? null : '/splash';

      final onboardingDone = settingsAsync.maybeWhen(
        data: (s) => s.onboardingCompleted,
        orElse: () => false,
      );

      // If we are on splash and settings are ready, decide where to go.
      if (isSplash) {
        return onboardingDone ? '/home' : '/onboarding';
      }

      // If onboarding not done and user somehow lands elsewhere, send back.
      if (!onboardingDone && !isOnboarding) return '/onboarding';

      return null; // no redirect
    },
    routes: [
      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Onboarding ────────────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ── Main shell (bottom nav) ────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Home branch
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: RouteNames.home,
              builder: (_, __) => const HomeScreen(),
            ),
          ]),
          // Calendar branch
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendar',
              name: RouteNames.calendar,
              builder: (_, __) => const CalendarScreen(),
            ),
          ]),
          // Statistics branch
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/statistics',
              name: RouteNames.statistics,
              builder: (_, __) => const StatisticsScreen(),
            ),
          ]),
          // Settings branch
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              name: RouteNames.settings,
              builder: (_, __) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'appearance',
                  name: RouteNames.appearance,
                  builder: (_, __) => const AppearanceScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),

      // ── Task routes (full-screen, outside shell) ───────────────────────────
      GoRoute(
        path: '/task/add',
        name: RouteNames.taskAdd,
        builder: (_, __) => const AddEditTaskScreen(),
      ),
      GoRoute(
        path: '/task/:id',
        name: RouteNames.taskDetail,
        builder: (_, state) =>
            TaskDetailScreen(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/task/:id/edit',
        name: RouteNames.taskEdit,
        builder: (_, state) =>
            AddEditTaskScreen(taskId: state.pathParameters['id']),
      ),

      // ── Other full-screen routes ───────────────────────────────────────────
      GoRoute(
        path: '/categories',
        name: RouteNames.categories,
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/search',
        name: RouteNames.search,
        builder: (_, __) => const SearchScreen(),
      ),
    ],
  );
});
