import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/order_models.dart';
import '../models/bill_models.dart';
import '../models/order_detail_models.dart' as order_detail;
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/address_service.dart';
import '../services/product_service.dart';
import '../services/order_details_service.dart';
import '../../features/payment/payment_screen.dart';

class BillCard extends StatefulWidget {
  final String planName;
  final String billLabel;
  final String amount;
  final String status;
  final BillHistory? billData;
  final VoidCallback? onPayPressed;
  final bool isProcessing;
  final bool useOrderDetails;
  final String? userId;
  final int? userAddressId;
  final order_detail.OrderDetail? orderDetailData;

  const BillCard({
    super.key,
    required this.planName,
    required this.billLabel,
    required this.amount,
    required this.status,
    this.billData,
    this.onPayPressed,
    this.isProcessing = false,
    this.useOrderDetails = false,
    this.userId,
    this.userAddressId,
    this.orderDetailData,
  });

  /// Constructor to create BillCard from OrderDetail
  factory BillCard.fromOrderDetail({
    required order_detail.OrderDetail orderDetail,
    String? userId,
    int? userAddressId,
    VoidCallback? onPayPressed,
    bool isProcessing = false,
  }) {
    return BillCard(
      planName: orderDetail.serviceName,
      billLabel: orderDetail.serviceGroup,
      amount: orderDetail.formattedAmount,
      status: orderDetail.displayStatus,
      billData: null,
      onPayPressed: onPayPressed,
      isProcessing: isProcessing,
      useOrderDetails: true,
      userId: userId,
      userAddressId: userAddressId,
      orderDetailData: orderDetail,
    );
  }

  @override
  State<BillCard> createState() => _BillCardState();
}

class _BillCardState extends State<BillCard> {
  bool _isProcessingPayment = false;
  final OrderDetailsService _orderDetailsService = OrderDetailsService.instance;
  order_detail.OrderDetail? _currentOrderDetail;

  @override
  void initState() {
    super.initState();
    if (widget.useOrderDetails && widget.userId != null) {
      _loadOrderDetails();
    }
  }

  /// Load order details as additional data source
  Future<void> _loadOrderDetails() async {
    if (widget.userId == null) return;

    try {
      final response = await _orderDetailsService.getOrderDetails(
        userId: widget.userId!,
        userAddressId: widget.userAddressId,
      );

      if (response != null && response.orders.isNotEmpty) {
        // Find matching order based on plan name or amount
        final matchingOrder = response.orders.where((order) {
          return order.serviceName.toLowerCase().contains(
                widget.planName.toLowerCase(),
              ) ||
              order.formattedAmount == widget.amount;
        }).firstOrNull;

        if (matchingOrder != null) {
          setState(() {
            _currentOrderDetail = matchingOrder;
          });
        }
      }
    } catch (e) {
      // Fallback to existing BillHistory data - no error shown to user
    }
  }

  /// Fallback method to handle bill payment using old flow (create order from bill)
  Future<void> _handleBillPaymentFallback() async {
    if (widget.billData == null) return;

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

        // Cache clearing removed - no longer needed

        // Navigate to payment screen with real API response
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PaymentScreen.fromOrderResponse(orderResponse: orderResponse),
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
    }
  }

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
      // Absolute fallback - this should rarely be used
      if (widget.billData?.invoiceId != null &&
          widget.billData!.invoiceId.isNotEmpty) {
        final parsed = int.tryParse(widget.billData!.invoiceId);
        if (parsed != null && parsed > 0) {
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
    // Priority 1: Use OrderDetail data directly passed from constructor
    if (widget.orderDetailData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen.fromOrderDetail(
            orderDetail: widget.orderDetailData!,
          ),
        ),
      ).then((_) {
        // Refresh data after payment
        if (mounted) {
          setState(() {});
        }
      });
      return;
    }

    // Priority 2: Use loaded OrderDetail data from API
    if (_currentOrderDetail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PaymentScreen.fromOrderDetail(orderDetail: _currentOrderDetail!),
        ),
      ).then((_) {
        // Refresh data after payment
        if (mounted) {
          _loadOrderDetails();
          setState(() {});
        }
      });
      return;
    }

    // Priority 3: Try to load OrderDetails for BillHistory data
    if (widget.billData != null && widget.userId != null) {
      setState(() {
        _isProcessingPayment = true;
      });

      try {
        // Try to get OrderDetails for this bill
        final response = await _orderDetailsService.getOrderDetails(
          userId: widget.userId!,
          userAddressId: widget.userAddressId,
        );

        if (response != null && response.orders.isNotEmpty) {
          // Find matching order for this bill (tidak peduli isPaid atau tidak)
          final matchingOrder = response.orders.where((order) {
            return order.midtransOrderId == widget.billData!.midtransOrderId ||
                order.formattedAmount == widget.amount;
          }).firstOrNull;

          if (matchingOrder != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PaymentScreen.fromOrderDetail(orderDetail: matchingOrder),
              ),
            ).then((_) {
              if (mounted) {
                _loadOrderDetails();
                setState(() {});
              }
            });
            return;
          }
        }

        // If no OrderDetails found, fallback to old flow (create order from bill)
        await _handleBillPaymentFallback();
      } catch (e) {
        // Fallback to old flow if OrderDetails loading fails
        await _handleBillPaymentFallback();
      } finally {
        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
          });
        }
      }
      return;
    }

    // Fallback to original onPayPressed if no bill data
    if (widget.onPayPressed != null) {
      widget.onPayPressed!();
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
                    // Hanya tampilkan button Pay jika status bukan "paid"
                    if (widget.status.toLowerCase() != 'paid')
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
