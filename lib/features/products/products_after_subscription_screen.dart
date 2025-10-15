import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/custom_gradient_header.dart';
import '../../core/widgets/banner_section.dart';
import '../../core/widgets/upgrade_care_widget.dart';
import '../../core/widgets/add_on_card_widget.dart';
import '../../core/services/product_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/address_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/bill_service.dart';
import '../home/home_screen.dart';
import '../../core/services/order_service.dart';
import '../../core/models/order_models.dart';

class ProductsAfterSubscriptionScreen extends StatefulWidget {
  final String currentPlan;

  const ProductsAfterSubscriptionScreen({super.key, required this.currentPlan});

  @override
  State<ProductsAfterSubscriptionScreen> createState() =>
      _ProductsAfterSubscriptionScreenState();
}

class _ProductsAfterSubscriptionScreenState
    extends State<ProductsAfterSubscriptionScreen> {
  List<Product> addOns = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadAddOns();
  }

  Future<void> _loadAddOns() async {
    try {
      final authService = AuthService();
      final userData = await authService.getCurrentUser();

      if (userData == null || userData['user_id'] == null) {
        setState(() {
          _errorMessage = 'Please login to view add-ons';
          _isLoading = false;
        });
        return;
      }

      _currentUserId = userData['user_id'];

      // Load subscription data first to get current subscription context
      final subscriptionResult = await SubscriptionService.instance
          .getUserSubscriptions(_currentUserId!);

      if (subscriptionResult['success'] == true &&
          subscriptionResult['data'] != null) {
        final subscriptions =
            subscriptionResult['data'] as Map<String, dynamic>;
        final subscriptionList =
            subscriptions['subscriptions'] as List<dynamic>? ?? [];

        if (subscriptionList.isNotEmpty) {
          // User has active subscription - load add-ons/upgrades
          await _loadAddOnsForSubscription(subscriptionList.first);
        } else {
          // No active subscription - should not be on this screen
          setState(() {
            _errorMessage = 'No active subscription found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load subscription data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading subscription: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAddOnsForSubscription(dynamic subscription) async {
    try {
      // Get current selected address
      final addressResult = await AddressService.instance.getUserAddresses(
        _currentUserId!,
      );
      int? selectedAddressId;

      if (addressResult['success'] == true && addressResult['data'] != null) {
        final addresses = addressResult['data'] as List<UserAddress>;
        if (addresses.isNotEmpty) {
          selectedAddressId = addresses.first.addressId;
        }
      }

      // Load products that can be add-ons for current subscription
      final result = await ProductService.instance.getAddOnsForSubscription(
        userId: _currentUserId!,
        subscriptionId: subscription['id'],
        addressId: selectedAddressId,
      );

      if (result['success'] == true && result['data'] != null) {
        final products = result['data'] as List<Product>;

        setState(() {
          addOns = products;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'No add-ons available';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading add-ons: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAddOns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _loadAddOns();
  }

  String _getProductIcon(String productName) {
    // Map product names to appropriate icons
    // You can expand this mapping based on your product catalog
    final lowerName = productName.toLowerCase();

    if (lowerName.contains('superpack')) {
      return 'assets/icons/superpack.png';
    } else if (lowerName.contains('hbo')) {
      return 'assets/icons/hbo.png';
    } else if (lowerName.contains('netflix')) {
      return 'assets/icons/netflix.png';
    } else if (lowerName.contains('disney')) {
      return 'assets/icons/disney.png';
    } else {
      // Default icon for unknown products
      return 'assets/icons/default_product.png';
    }
  }

  void _handleBuyAddOn(Product product) {
    _showPurchaseDialog(product);
  }

  void _showPurchaseDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Purchase ${product.name}',
          style: const TextStyle(fontFamily: 'Open Sans'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product: ${product.name}',
              style: const TextStyle(fontFamily: 'Open Sans'),
            ),
            const SizedBox(height: 8),
            Text(
              'Price: ${product.formattedPrice}',
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Do you want to proceed with this purchase?',
              style: TextStyle(fontFamily: 'Open Sans'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _processOrder(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CB04C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Purchase'),
          ),
        ],
      ),
    );
  }

  Future<void> _processOrder(Product product) async {
    if (_currentUserId == null) return;

    // Show loading dialog with proper UI
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
              'Processing order...',
              style: TextStyle(fontFamily: 'Open Sans'),
            ),
          ],
        ),
      ),
    );

    try {
      // Get selected address
      final addressResult = await AddressService.instance.getUserAddresses(
        _currentUserId!,
      );
      int? selectedAddressId;

      if (addressResult['success'] == true && addressResult['data'] != null) {
        final addresses = addressResult['data'] as List<UserAddress>;
        if (addresses.isNotEmpty) {
          selectedAddressId = addresses.first.addressId;
        }
      }

      // Create order request
      final orderRequest = OrderRequest(
        userId: _currentUserId!,
        productId: product.pid,
        userAddressId: selectedAddressId ?? 1,
        level: '1',
        block: 'A',
        unitNumber: '001',
      );

      // Create order
      final orderResult = await OrderService.instance.createOrder(orderRequest);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (orderResult['success'] == true) {
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
                  'Your order for ${product.name} has been placed successfully.',
                  style: const TextStyle(fontFamily: 'Open Sans'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A new bill has been generated and added to your account.',
                  style: TextStyle(fontFamily: 'Open Sans'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You will be redirected to the home page.',
                  style: TextStyle(fontFamily: 'Open Sans'),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
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
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderResult['message'] ?? 'Failed to create order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToHome() {
    // Clear ALL cached data for complete refresh after successful order
    if (_currentUserId != null) {
      // Clear specific user cache
      BillService.instance.clearCache(userId: _currentUserId!);
      ProductService.instance.clearCache(userId: _currentUserId!);

      print(
        'Clearing all caches after successful add-on order for user: $_currentUserId',
      );
    } else {
      // Clear all cache if userId not available
      BillService.instance.clearCache();
      ProductService.instance.clearCache();
      print('Clearing all caches after successful add-on order (no userId)');
    }

    // Navigate to home
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header dengan search
          CustomGradientHeader(
            title: 'Products',
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search Product',
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontFamily: 'Open Sans',
                          fontSize: 14,
                        ),
                        suffixIcon: Icon(
                          Icons.search,
                          color: Colors.black.withOpacity(0.7),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recommended For You Section
                  const Text(
                    'Recommended For You',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Open Sans',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Banner Section
                  const BannerSection(),

                  const SizedBox(height: 24),

                  // Upgrade Care Widget
                  UpgradeCareWidget(
                    currentPlan: widget.currentPlan,
                    onUpgradePressed: () {
                      // Handle upgrade action
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Upgrade feature coming soon!'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Add-ons Section
                  const Text(
                    'Add-ons',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Open Sans',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Add-ons List
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontFamily: 'Open Sans',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _refreshAddOns,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (addOns.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No add-ons available',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ...addOns
                        .map(
                          (product) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AddOnCardWidget(
                              iconAsset: _getProductIcon(product.name),
                              title: product.name,
                              price: product.formattedPrice,
                              onBuyPressed: () {
                                _handleBuyAddOn(product);
                              },
                            ),
                          ),
                        )
                        .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/products'),
    );
  }
}
