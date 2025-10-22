import 'package:flutter/material.dart';
import '../models/order_models.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/address_service.dart';
import '../services/auth_service.dart';
import '../services/bill_service.dart';
import '../../features/home/home_screen.dart';

class OrderDialog extends StatefulWidget {
  final Product product;

  const OrderDialog({super.key, required this.product});

  @override
  State<OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<OrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _levelController = TextEditingController();
  final _blockController = TextEditingController();
  final _unitNumberController = TextEditingController();

  bool _isLoading = false;
  String? _userId;
  int? _selectedAddressId;
  List<UserAddress> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get current user from auth service
      final authService = AuthService();
      final userData = await authService.getCurrentUser();

      if (userData != null && userData['user_id'] != null) {
        _userId = userData['user_id'];
        await _loadAddresses();
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadAddresses() async {
    if (_userId == null) return;

    try {
      final result = await AddressService.instance.getUserAddresses(_userId!);
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _addresses = result['data'] as List<UserAddress>;
          if (_addresses.isNotEmpty) {
            _selectedAddressId = _addresses.first.addressId;
          }
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) return;

    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            const Text(
              'Processing your order...',
              style: TextStyle(fontFamily: 'Open Sans'),
            ),
          ],
        ),
      ),
    );

    try {
      final orderRequest = OrderRequest(
        userId: _userId!,
        productId: widget.product.pid,
        userAddressId: _selectedAddressId!,
        level: _levelController.text.trim().isEmpty
            ? '1'
            : _levelController.text.trim(),
        block: _blockController.text.trim().isEmpty
            ? 'A'
            : _blockController.text.trim(),
        unitNumber: _unitNumberController.text.trim().isEmpty
            ? '001'
            : _unitNumberController.text.trim(),
      );

      final result = await OrderService.instance.createOrder(orderRequest);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result['success'] == true && result['data'] != null) {
        final orderResponse = result['data'] as OrderResponse;

        // Close the order dialog
        Navigator.of(context).pop();

        // Show success popup
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text(
                  'Order Successful!',
                  style: TextStyle(fontFamily: 'Open Sans'),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your order for ${widget.product.name} has been placed successfully.',
                  style: const TextStyle(fontFamily: 'Open Sans'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order ID: ${orderResponse.midtransOrderId}',
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A new bill has been generated and added to your account.',
                  style: TextStyle(fontFamily: 'Open Sans'),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close success dialog
                  _navigateToHome();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontFamily: 'Open Sans'),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _levelController.dispose();
    _blockController.dispose();
    _unitNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Form order',
        style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Open Sans'),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Level input
              const Text(
                'Level',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: 'Open Sans',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _levelController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 2',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter level';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Block input
              const Text(
                'Block',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: 'Open Sans',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _blockController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., A',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter block';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Unit Number input
              const Text(
                'Unit Number',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: 'Open Sans',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _unitNumberController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 201',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter unit number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(fontFamily: 'Open Sans'),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CB04C),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Order Now',
                  style: TextStyle(fontFamily: 'Open Sans'),
                ),
        ),
      ],
    );
  }

  void _navigateToHome() {
    // Clear ALL cached data for complete refresh after successful order
    if (_userId != null) {
      // Clear specific user cache
      BillService.instance.clearCache(userId: _userId!);
      ProductService.instance.clearCache(userId: _userId!);

      // Clear all subscription cache to get latest subscription data
      // Since SubscriptionService doesn't have userId-specific clearing, we clear all
      print('Clearing all caches after successful order for user: $_userId');
    } else {
      // Clear all cache if userId not available
      BillService.instance.clearCache();
      ProductService.instance.clearCache();
      print('Clearing all caches after successful order (no userId)');
    }

    // Navigate to home
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }
}
