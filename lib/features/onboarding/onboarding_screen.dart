import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:liquid_swipe/liquid_swipe.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  bool _isUserInteracting = true;

  final _pages = const [
    _OnboardPageData(
      title: 'Lebih Cepat Lebih Hemat!',
      subtitle:
          'Internet super cepat dengan berbagai macam pilihan paket yang ekonomis. Pilih paket sesuai keinginanmu dan nikmati keseruannya.',
    ),
    _OnboardPageData(
      title: 'Nonton film kekinian, nyaman seharian',
      subtitle:
          'Bebas lancar nonton film di semua platform, Netflix, Disney+ Hotstar, Mola, Video, Viu, dan lain-lain tanpa batas.',
    ),
    _OnboardPageData(
      title: 'Internet Broadband Tercepat Tanpa Batas!',
      subtitle:
          'Koneksi selalu ON dan selalu bisa diandalkan. Dapatkan pengalaman internetan seru dengan fitur dan keunggulan layanan Livinet.',
    ),
  ];

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlideTimer();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isUserInteracting && mounted) {
        _autoNext();
      }
    });
  }

  void _stopAutoSlideTimer() {
    _autoSlideTimer?.cancel();
  }

  void _resetAutoSlideTimer() {
    _startAutoSlideTimer();
  }

  void _autoNext() {
    if (_index >= _pages.length - 1) {
      _stopAutoSlideTimer();
      _finish();
    } else {
      final next = _index + 1;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() => context.go('/login');

  void _next() {
    _stopAutoSlideTimer();
    _isUserInteracting = true;

    if (_index >= _pages.length - 1) {
      _finish();
    } else {
      final next = _index + 1;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }

    // Reset user interaction flag after animation
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _isUserInteracting = false;
        _resetAutoSlideTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gaps.lg, Gaps.sm, Gaps.lg, 0),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: c.secondary,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final maxH = constraints.maxHeight;

                  final horizontalPad = math.min(
                    math.max(maxW * 0.06, 12.0),
                    32.0,
                  );
                  final placeholderSize = math.min(
                    math.max(maxW * 0.90, 260.0),
                    maxH * 0.50,
                  );

                  const double textTopGap = 32.0;
                  const double titleSubtitleGap = 14.0;

                  return Column(
                    children: [
                      // Swipeable content
                      Expanded(
                        child: GestureDetector(
                          onPanStart: (_) {
                            _isUserInteracting = true;
                            _stopAutoSlideTimer();
                          },
                          onPanEnd: (_) {
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                if (mounted) {
                                  _isUserInteracting = false;
                                  _resetAutoSlideTimer();
                                }
                              },
                            );
                          },
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _pages.length,
                            physics: const BouncingScrollPhysics(),
                            onPageChanged: (i) {
                              setState(() => _index = i);
                              if (!_isUserInteracting) {
                                _resetAutoSlideTimer();
                              }
                            },
                            itemBuilder: (context, i) {
                              return AnimatedBuilder(
                                animation: _pageController,
                                builder: (context, child) {
                                  double value = 1.0;
                                  if (_pageController.position.haveDimensions) {
                                    value = _pageController.page! - i;
                                    value = (1 - (value.abs() * 0.3)).clamp(
                                      0.0,
                                      1.0,
                                    );
                                  }

                                  final p = _pages[i];
                                  return Transform.scale(
                                    scale: Curves.easeOut.transform(value),
                                    child: Opacity(
                                      opacity: value,
                                      child: Container(
                                        color: Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: horizontalPad,
                                          ),
                                          child: Align(
                                            alignment: const Alignment(
                                              0,
                                              -0.15,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TweenAnimationBuilder<double>(
                                                  duration: const Duration(
                                                    milliseconds: 600,
                                                  ),
                                                  tween: Tween(
                                                    begin: 0.0,
                                                    end: value,
                                                  ),
                                                  builder: (context, animValue, child) {
                                                    return Transform.translate(
                                                      offset: Offset(
                                                        0,
                                                        20 * (1 - animValue),
                                                      ),
                                                      child: Container(
                                                        width: placeholderSize,
                                                        height: placeholderSize,
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFFE0E0E0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.05 *
                                                                        animValue,
                                                                  ),
                                                              blurRadius: 12,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    4,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(
                                                  height: textTopGap,
                                                ),
                                                TweenAnimationBuilder<double>(
                                                  duration: const Duration(
                                                    milliseconds: 800,
                                                  ),
                                                  tween: Tween(
                                                    begin: 0.0,
                                                    end: value,
                                                  ),
                                                  builder: (context, animValue, child) {
                                                    return Transform.translate(
                                                      offset: Offset(
                                                        0,
                                                        30 * (1 - animValue),
                                                      ),
                                                      child: Opacity(
                                                        opacity: animValue,
                                                        child: Text(
                                                          p.title,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 24,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(
                                                  height: titleSubtitleGap,
                                                ),
                                                TweenAnimationBuilder<double>(
                                                  duration: const Duration(
                                                    milliseconds: 1000,
                                                  ),
                                                  tween: Tween(
                                                    begin: 0.0,
                                                    end: value,
                                                  ),
                                                  builder: (context, animValue, child) {
                                                    return Transform.translate(
                                                      offset: Offset(
                                                        0,
                                                        40 * (1 - animValue),
                                                      ),
                                                      child: Opacity(
                                                        opacity: animValue,
                                                        child: ConstrainedBox(
                                                          constraints:
                                                              BoxConstraints(
                                                                maxWidth:
                                                                    maxW * 0.9,
                                                              ),
                                                          child: Text(
                                                            p.subtitle,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withOpacity(
                                                                        0.75,
                                                                      ),
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),

                      // Fixed dots at bottom (above button)
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 24),
                        child: _Dots(
                          count: _pages.length,
                          activeIndex: _index,
                          activeColor: c.secondary,
                          inactiveColor: const Color(0xFFEAEAEA),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.lg),
              child: AppButton(
                text: _index == _pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: _next,
                isPrimary: true,
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
  const _OnboardPageData({required this.title, required this.subtitle});
}

class _Dots extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;

  const _Dots({
    required this.count,
    required this.activeIndex,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 20 : 8,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
