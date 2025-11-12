// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:livinet_mobile/features/login/login_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/signup/signup_screen.dart';
import '../../features/forgotpass/forgotpass_screen.dart';
import '../../features/pay/pay_screen.dart';
import '../../features/products/products_screen.dart';
import '../../features/help/help_screen.dart';
import '../../features/profile/profile_screen.dart';

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    opaque: false,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadePage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _fadePage(state, const SignupScreen()),
      ),
      GoRoute(
        path: '/forgotpass',
        pageBuilder: (context, state) =>
            _fadePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _fadePage(
            state,
            HomeScreen(shouldRefresh: extra?['shouldRefresh'] ?? false),
          );
        },
      ),
      GoRoute(
        path: '/pay',
        pageBuilder: (context, state) => _fadePage(state, const PayScreen()),
      ),
      GoRoute(
        path: '/products',
        pageBuilder: (context, state) =>
            _fadePage(state, const ProductsScreen()),
      ),
      GoRoute(
        path: '/help',
        pageBuilder: (context, state) => _fadePage(state, const HelpScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _fadePage(state, const ProfileScreen()),
      ),
    ],
  );
}
