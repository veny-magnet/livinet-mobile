import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoFade;
  late final AnimationController _exitController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await _exitController.reverse();
      if (!mounted) return;
      context.pushReplacement('/onboarding');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final shortestSide = media.size.shortestSide;
    final isTablet = shortestSide >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: FadeTransition(
          opacity: _exitController,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4CB04C), Color(0xFFF8D86E)],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final baseFactor = isTablet ? 0.28 : 0.45;
                  double logoWidth = maxW * baseFactor;
                  const double minLogo = 120;
                  const double maxLogo = 300;
                  if (logoWidth < minLogo) logoWidth = minLogo;
                  if (logoWidth > maxLogo) logoWidth = maxLogo;

                  final spacing = (constraints.maxHeight * 0.015).clamp(8.0, 24.0);

                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (maxW * 0.06).clamp(12.0, 48.0),
                      ),
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              label: 'App logo',
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                width: logoWidth,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: spacing),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
