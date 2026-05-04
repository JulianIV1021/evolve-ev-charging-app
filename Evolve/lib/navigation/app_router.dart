import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/stations/stations_map_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/activity/session_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/vehicle_profile_screen.dart';
import '../screens/navigation/navigation_flow_screen.dart';
import '../screens/navigation/route_options_screen.dart';
import '../screens/navigation/route_preview_screen.dart';
import '../screens/navigation/turn_by_turn_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import 'main_shell.dart';

/// Root navigator key — used to display full-screen routes that bypass the
/// tab shell (navigation, route options, session detail, vehicle profile).
final _rootKey = GlobalKey<NavigatorState>();

/// Listens to Firebase auth state and notifies GoRouter so it re-runs
/// its redirect when the session changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _initialized = true;
      notifyListeners();
    });
  }

  bool _initialized = false;
  bool get initialized => _initialized;

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authNotifier = _AuthChangeNotifier();

/// Central GoRouter instance used by the entire app.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/splash',
  refreshListenable: _authNotifier,
  redirect: (context, state) async {
    if (!_authNotifier.initialized) {
      return state.matchedLocation == '/splash' ? null : '/splash';
    }

    final user = FirebaseAuth.instance.currentUser;
    final loc = state.matchedLocation;
    const publicRoutes = {'/login', '/signup', '/forgot-password', '/onboarding'};

    if (user == null) {
      if (loc == '/onboarding') return null;
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('onboarding_complete') ?? false;
      if (!done) return '/onboarding';
      return publicRoutes.contains(loc) ? null : '/login';
    }

    if (loc == '/splash' || publicRoutes.contains(loc)) {
      return '/shell/stations';
    }

    return null;
  },
  routes: [
    // Public / auth routes
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (c, s) => const SignUpScreen()),
    GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),

    // Full-screen routes (root navigator — no tab bar)
    GoRoute(
      path: '/route-options',
      parentNavigatorKey: _rootKey,
      builder: (c, s) => const RouteOptionsScreen(),
    ),
    GoRoute(
      path: '/navigation-flow',
      parentNavigatorKey: _rootKey,
      builder: (c, s) => const NavigationFlowScreen(),
    ),
    GoRoute(
      path: '/route-preview',
      parentNavigatorKey: _rootKey,
      builder: (c, s) => const RoutePreviewScreen(),
    ),
    GoRoute(
      path: '/navigation',
      parentNavigatorKey: _rootKey,
      builder: (c, s) => const TurnByTurnScreen(),
    ),
    GoRoute(
      path: '/activity/session',
      parentNavigatorKey: _rootKey,
      builder: (c, s) {
        final session = s.extra as Map<String, dynamic>? ?? {};
        return SessionDetailScreen(session: session);
      },
    ),
    GoRoute(
      path: '/profile/vehicle',
      parentNavigatorKey: _rootKey,
      builder: (c, s) => const VehicleProfileScreen(),
    ),

    // Tab shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/shell/stations', builder: (c, s) => const StationsMapScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/shell/search', builder: (c, s) => const SearchScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/shell/scan', builder: (c, s) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/shell/activity', builder: (c, s) => const ActivityScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/shell/profile', builder: (c, s) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);
