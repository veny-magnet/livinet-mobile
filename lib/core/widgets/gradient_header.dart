import 'package:flutter/material.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final double height;

  const GradientHeader({
    super.key,
    required this.title,
    this.action,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CB04C), Color(0xFFF8D86E)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Open Sans',
                ),
              ),
              if (action != null) action!,
            ],
          ),
        ),
      ),
    );
  }
}
