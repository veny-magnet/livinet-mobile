import 'package:flutter/material.dart';
import '../../core/services/product_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/address_manager.dart';
import '../../core/services/subscription_service.dart';
import '../../core/widgets/product_card.dart';

class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  bool isLoading = true;
  List<Product> products = [];
  String errorMessage = '';
  String userId = '';
  Map<String, dynamic>? currentSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadProducts();
    await _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      if (userId.isEmpty) return;

      final result = await SubscriptionService.instance.getActiveSubscription(
        userId,
      );

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          currentSubscription = result['data'];
        });
      }
    } catch (e) {}
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Get user ID from AuthService
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();

      if (currentUser == null || currentUser['code'] == null) {
        setState(() {
          errorMessage = 'User session not found';
          isLoading = false;
        });
        return;
      }

      userId = currentUser['code'] as String;

      // Get selected address
      final selectedAddressCode = AddressManager.instance.selectedAddressCode;

      // Get products from service
      final result = await ProductService.instance.getProducts(
        userId: userId,
        addressId: selectedAddressCode,
      );

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          products = result['data'] as List<Product>;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load products';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading products: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _showUpgradeConfirmation(Product targetProduct) async {
    if (currentSubscription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active subscription found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentProductName =
        currentSubscription?['subsplanName'] ?? 'Current Plan';

    // State untuk tanggal instalasi
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Confirm Upgrade',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'Upgrade from '),
                        TextSpan(
                          text: currentProductName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CB04C),
                          ),
                        ),
                        const TextSpan(text: ' to '),
                        TextSpan(
                          text: targetProduct.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CB04C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Installation Date Picker
                  const Text(
                    'Installation Date',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF4CB04C),
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Color(0xFF4CB04C),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? 'Select installation date'
                                  : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 14,
                                color: selectedDate == null
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your request will be sent to admin for approval. You will be notified once processed.',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedDate == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _submitUpgradeRequest(targetProduct, selectedDate!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CB04C),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text(
                    'Submit Request',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitUpgradeRequest(
    Product targetProduct,
    DateTime installationDate,
  ) async {
    if (currentSubscription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active subscription found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Submitting upgrade request...',
                style: TextStyle(fontFamily: 'Open Sans'),
              ),
            ],
          ),
        );
      },
    );

    try {
      // Format installation date (YYYY-MM-DD)
      final formattedDate =
          '${installationDate.year}-${installationDate.month.toString().padLeft(2, '0')}-${installationDate.day.toString().padLeft(2, '0')}';

      final result = await SubscriptionService.instance.upgradeSubscription(
        userId: userId,
        subscriptionId: currentSubscription!['subsplanID'].toString(),
        targetProductId: targetProduct.pid.toString(),
        installationDate: formattedDate,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result['success'] == true) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CB04C), size: 24),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Request Submitted',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                result['message'] ??
                    'Your upgrade request has been sent to admin. You will be notified once it is processed.',
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CB04C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontFamily: 'Open Sans', fontSize: 14),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to submit upgrade request',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 30),
        ),
        title: const Text(
          'Choose plan to upgrade',
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProducts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CB04C),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : products.isEmpty
          ? const Center(
              child: Text(
                'No upgrade plans available',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Open Sans',
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      _showUpgradeConfirmation(product);
                    },
                  );
                },
              ),
            ),
    );
  }
}
