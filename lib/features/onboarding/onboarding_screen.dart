import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart'; // for Gaps, colors if you want

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardPageData(
      title: 'Welcome to Livinet',
      subtitle: 'Do more with less taps.',
      icon: Icons.explore,
    ),
    _OnboardPageData(
      title: 'Fast & Secure',
      subtitle: 'Your data stays safe.',
      icon: Icons.lock_outline,
    ),
    _OnboardPageData(
      title: 'Stay Productive',
      subtitle: 'Tools designed for your workflow.',
      icon: Icons.bolt_outlined,
    ),
  ];

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  void _finish() {
    // TODO: Persist "onboardingSeen = true" with SharedPreferences
    context.go('/home'); // navigate to your next screen (login/home)
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button top-right
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p.icon, size: 120, color: c.primary),
                        const SizedBox(height: Gaps.lg),
                        Text(p.title, style: t.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: Gaps.sm),
                        Text(p.subtitle, style: t.bodyMedium, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                  height: 8,
                  width: active ? 20 : 8,
                  decoration: BoxDecoration(
                    color: active ? c.primary : c.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
            // Next / Done
            Padding(
              padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_index == _pages.length - 1 ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPageData {
  final String title;
  final String subtitle;
  final IconData icon;
  const _OnboardPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
