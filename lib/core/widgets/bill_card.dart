import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/order_models.dart';
import '../models/bill_models.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/address_service.dart';
import '../services/product_service.dart';
import '../services/bill_service.dart';
import '../../features/payment/payment_screen.dart';

class BillCard extends StatefulWidget {
  final String planName;
  final String billLabel;
  final String amount;
  final String status;
  final BillHistory? billData;
  final VoidCallback? onPayPressed;
  final bool isProcessing;

  const BillCard({
    super.key,
    required this.planName,
    required this.billLabel,
    required this.amount,
    required this.status,
    this.billData,
    this.onPayPressed,
    this.isProcessing = false,
  });

  @override
  State<BillCard> createState() => _BillCardState();
}

class _BillCardState extends State<BillCard> {
  bool _isProcessingPayment = false;

  /// Get appropriate product ID for bill payment
  Future<int> _getProductIdForBill(String userId, int userAddressId) async {
    try {
      // Use the dedicated ProductService method for getting bill-specific product ID
      final productId = await ProductService.instance.getProductIdForBill(
        userId: userId,
        userAddressId: userAddressId,
        planName: widget.planName,
        invoiceId: widget.billData?.invoiceId,
      );

      if (productId != null) {
        return productId;
      }

      // If ProductService couldn't find a suitable product ID, return error
      throw Exception('No suitable product found for bill payment');
    } catch (e) {
      print('Error getting product ID for bill: $e');

      // Absolute fallback - this should rarely be used
      if (widget.billData?.invoiceId != null &&
          widget.billData!.invoiceId.isNotEmpty) {
        final parsed = int.tryParse(widget.billData!.invoiceId);
        if (parsed != null && parsed > 0) {
          print('Using invoice ID as ultimate fallback: $parsed');
          return parsed;
        }
      }

      // Should not reach here in production - indicates a data/API issue
      throw Exception('Unable to determine product ID for bill payment');
    }
  }

  Future<Map<String, String>?> _showBillPaymentDialog() async {
    final levelController = TextEditingController();
    final blockController = TextEditingController();
    final unitNumberController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Payment Details',
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please provide your installation details for bill payment:',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: levelController,
                decoration: const InputDecoration(
                  labelText: 'Level/Floor',
                  hintText: 'e.g., 1, 2, 3',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: blockController,
                decoration: const InputDecoration(
                  labelText: 'Block',
                  hintText: 'e.g., A, B, C',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitNumberController,
                decoration: const InputDecoration(
                  labelText: 'Unit Number',
                  hintText: 'e.g., 001, 102, 203',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (levelController.text.trim().isEmpty ||
                    blockController.text.trim().isEmpty ||
                    unitNumberController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop({
                  'level': levelController.text.trim(),
                  'block': blockController.text.trim(),
                  'unitNumber': unitNumberController.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CB04C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue Payment'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      levelController.dispose();
      blockController.dispose();
      unitNumberController.dispose();
    });
  }

  Future<void> _handlePayment() async {
    if (widget.billData == null) {
      // Fallback to original onPayPressed if no bill data
      if (widget.onPayPressed != null) {
        widget.onPayPressed!();
      }
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Get current user data
      final authService = AuthService();
      final userData = await authService.getCurrentUser();

      if (userData == null || userData['user_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first to make payment'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get user addresses to use in order
      final addressResult = await AddressService.instance.getUserAddresses(
        userData['user_id'],
      );

      if (addressResult['success'] != true || addressResult['data'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              addressResult['message'] ?? 'Failed to get user addresses',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final addresses = addressResult['data'] as List<UserAddress>;
      if (addresses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No addresses found. Please add an address first.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show dialog to collect level, block, unitNumber for bill payment
      final orderDetails = await _showBillPaymentDialog();
      if (orderDetails == null) {
        return; // User cancelled
      }

      // Use bill's userAddressId if available, otherwise use first address
      final userAddressId =
          widget.billData!.userAddressId ?? addresses.first.addressId;

      // Get product ID from API based on bill context
      final productId = await _getProductIdForBill(
        userData['user_id'],
        userAddressId,
      );

      // Create order request for existing bill payment
      final orderRequest = OrderRequest(
        userId: userData['user_id'],
        productId: productId,
        userAddressId: userAddressId,
        level: orderDetails['level']!,
        block: orderDetails['block']!,
        unitNumber: orderDetails['unitNumber']!,
      );

      // Call real API to create order
      final result = await OrderService.instance.createOrder(orderRequest);

      if (result['success'] == true && result['data'] != null) {
        final orderResponse = result['data'] as OrderResponse;

        // Clear caches to ensure fresh data after payment
        ProductService.instance.clearCache(userId: userData['user_id']);
        BillService.instance.clearCache(userId: userData['user_id']);

        // Navigate to payment screen with real API response
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(orderResponse: orderResponse),
          ),
        ).then((_) {
          // Additional refresh when returning from payment screen
          if (mounted) {
            // Trigger a rebuild of parent widgets if needed
            setState(() {});
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to create payment order',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

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
                  widget.planName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.8),
                    fontFamily: 'Open Sans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.billLabel,
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
                        widget.amount,
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
                      onPressed: (_isProcessingPayment || widget.isProcessing)
                          ? null
                          : _handlePayment,
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
                      child: (_isProcessingPayment || widget.isProcessing)
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
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
                      'Status',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black.withOpacity(0.6),
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.7),
                          fontFamily: 'Open Sans',
                          letterSpacing: 0.5,
                        ),
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
