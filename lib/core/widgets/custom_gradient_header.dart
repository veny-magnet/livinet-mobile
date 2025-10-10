import 'dart:ui';
import 'package:flutter/material.dart';

class CustomGradientHeader extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? action;

  const CustomGradientHeader({
    super.key,
    required this.title,
    required this.children,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Minimal top spacing
              const SizedBox(height: 2),

              // Title and optional action
              if (action != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    action!,
                  ],
                )
              else
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Open Sans',
                  ),
                ),

              const SizedBox(height: 12),

              ...children,

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
