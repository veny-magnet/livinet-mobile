import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';

class AppRouter {
  static CustomTransitionPage<void> _fadePage(Widget child) {
    return CustomTransitionPage<void>(
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => _fadePage(const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _fadePage(const OnboardingScreen()),
      ),
      // Placeholder home so buttons have somewhere to go
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _fadePage(const HomeScreen()),
      ),
    ],
  );
}
