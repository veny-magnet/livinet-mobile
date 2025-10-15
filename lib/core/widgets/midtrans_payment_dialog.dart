import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order_models.dart';

class MidtransPaymentDialog extends StatefulWidget {
  final String redirectUrl;
  final OrderResponse orderResponse;
  final Function(bool success) onPaymentComplete;

  const MidtransPaymentDialog({
    super.key,
    required this.redirectUrl,
    required this.orderResponse,
    required this.onPaymentComplete,
  });

  @override
  State<MidtransPaymentDialog> createState() => _MidtransPaymentDialogState();
}

class _MidtransPaymentDialogState extends State<MidtransPaymentDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF4CB04C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Complete Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.onPaymentComplete(false);
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Order Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF8F9FA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.orderResponse.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.orderResponse.formattedAmount,
                    style: const TextStyle(
                      color: Color(0xFF4CB04C),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ],
              ),
            ),

            // Payment Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Link',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.redirectUrl,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Open Sans',
                                color: Colors.blue,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.redirectUrl),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Payment link copied to clipboard',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Please click the button below to open the payment page in your browser.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    const Spacer(),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              widget.onPaymentComplete(false);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontFamily: 'Open Sans'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // For now, we'll just simulate success
                              // In a real app, you'd open the URL and check for payment completion
                              widget.onPaymentComplete(true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CB04C),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Open Payment',
                              style: TextStyle(fontFamily: 'Open Sans'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
