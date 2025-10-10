import 'dart:ui';
import 'package:flutter/material.dart';

class BillCard extends StatelessWidget {
  final String planName;
  final String billLabel;
  final String amount;
  final String lastPaymentDate;
  final VoidCallback? onPayPressed;

  const BillCard({
    super.key,
    required this.planName,
    required this.billLabel,
    required this.amount,
    required this.lastPaymentDate,
    this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.8),
                    fontFamily: 'Open Sans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  billLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withOpacity(0.6),
                    fontFamily: 'Open Sans',
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        amount,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withOpacity(0.8),
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: onPayPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CB04C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 10,
                        ),
                        minimumSize: const Size(60, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Pay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Divider(
                  color: Colors.black.withOpacity(0.2),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Latest payment on:',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black.withOpacity(0.6),
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    Text(
                      lastPaymentDate,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black.withOpacity(0.8),
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
