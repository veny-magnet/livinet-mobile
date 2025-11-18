import 'package:flutter/material.dart';
import '../models/order_models.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/address_service.dart';
import '../services/auth_service.dart';

class OrderDialog extends StatefulWidget {
  final Product product;
  final Function(OrderResponse orderResponse) onOrderSuccess;

  const OrderDialog({
    super.key,
    required this.product,
    required this.onOrderSuccess,
  });

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
  String? _selectedAddressCode;
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

      if (userData != null && userData['code'] != null) {
        _userId = userData['code']; // Use UUID (code) as userId
        await _loadAddresses();
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
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
            _selectedAddressCode = _addresses.first.code;
          }
        });
      }
    } catch (e) {
      // Handle error silently or show message if needed
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) return;

    if (_selectedAddressCode == null) {
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
      builder: (loadingContext) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(
              'Processing your order',
              style: TextStyle(fontFamily: 'Open Sans'),
            ),
          ],
        ),
      ),
    );

    try {
      final orderRequest = OrderRequest(
        userCode: _userId!,
        productId: widget.product.pid,
        addressCode: _selectedAddressCode!,
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

        // Close order dialog
        if (mounted) Navigator.of(context).pop();

        // Call callback to show success dialog in parent screen
        widget.onOrderSuccess(orderResponse);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  hintText: 'e.g., 2',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4CB04C),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
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
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  hintText: 'e.g., A',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4CB04C),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
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
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  hintText: 'e.g., 201',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4CB04C),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
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
}
