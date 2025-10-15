import 'dart:ui';
import 'package:flutter/material.dart';

class NoPlanWidget extends StatelessWidget {
  final VoidCallback? onBuyPlanPressed;

  const NoPlanWidget({super.key, this.onBuyPlanPressed});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No plan yet!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF484C4F),
                  fontFamily: 'Open Sans',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Explore and buy plan to continue using the app',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontFamily: 'Open Sans',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      onBuyPlanPressed ??
                      () {
                        Navigator.pushNamed(context, '/products');
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CB04C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Buy Plan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
