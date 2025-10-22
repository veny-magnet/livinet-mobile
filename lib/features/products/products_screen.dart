import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/custom_gradient_header.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/not_verified_widget.dart';
import '../../core/widgets/banner_section.dart';
import '../../core/widgets/upgrade_card_widget.dart';
import '../../core/widgets/add_on_card_widget.dart';
import '../../core/services/user_profile_service.dart';
import '../../core/services/product_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/address_manager.dart';
import '../../core/services/address_service.dart';
import '../../core/services/bill_service.dart';
import '../../core/services/order_service.dart';
import '../../core/models/order_models.dart';
import 'products_detail_screen.dart';
import 'upgrade_plan_screen.dart';
import '../home/home_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String status = '';
  String userId = '';
  bool isLoading = true;
  List<Product> products = [];
  List<Product> addOns = [];
  String errorMessage = '';
  bool hasSubscription = false;
  String currentPlan = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // Listen to address changes
    AddressManager.instance.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    // Remove listener when disposing
    AddressManager.instance.removeListener(_onAddressChanged);
    super.dispose();
  }

  void _onAddressChanged(UserAddress? address) {
    // Clear product cache before loading new products
    if (status == 'verified' && userId.isNotEmpty) {
      ProductService.instance.clearCache(userId: userId);

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          if (hasSubscription) {
            _loadAddOns(userId, address?.addressId);
          } else {
            _loadProducts(userId, address?.addressId);
          }
        }
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final result = await UserProfileService.instance.getCurrentUserProfile();

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          status = data.status ?? '';
          userId = data.userId ?? '';
        });

        if (status == 'verified' && userId.isNotEmpty) {
          await AddressManager.instance.loadDefaultAddress(userId);

          // Check if user has subscription first
          await _checkUserSubscription(userId);
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          status = '';
          userId = '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = '';
        userId = '';
        isLoading = false;
        errorMessage = 'Error loading profile: $e';
      });
    }
  }

  Future<void> _checkUserSubscription(String userId) async {
    try {
      print('ProductsScreen: Checking subscription for user: $userId');

      final subscriptionResult = await SubscriptionService.instance
          .getUserSubscriptions(userId);

      print('ProductsScreen: Subscription result: $subscriptionResult');
      print('ProductsScreen: Success: ${subscriptionResult['success']}');
      print('ProductsScreen: Data: ${subscriptionResult['data']}');

      if (subscriptionResult['success'] == true &&
          subscriptionResult['data'] != null &&
          subscriptionResult['data']['subscriptions'] != null &&
          (subscriptionResult['data']['subscriptions'] as List).isNotEmpty) {
        // User has subscription - show add-ons view
        final subscriptions =
            subscriptionResult['data']['subscriptions'] as List;

        print('ProductsScreen: Found ${subscriptions.length} subscription(s)');
        print('ProductsScreen: Subscription data: ${subscriptions.first}');

        final planName =
            subscriptions.first['subsplanName']?.toString() ??
            subscriptions.first['productDescription']?.toString() ??
            'Current Plan';

        print('ProductsScreen: Plan name: $planName');

        setState(() {
          hasSubscription = true;
          currentPlan = planName;
        });

        print('ProductsScreen: hasSubscription set to TRUE');

        // Load add-ons for subscription
        final selectedAddressId = AddressManager.instance.selectedAddressId;
        await _loadAddOns(userId, selectedAddressId);
      } else {
        // No subscription, load products normally
        print('ProductsScreen: No active subscription found');
        print('ProductsScreen: Loading products instead...');

        setState(() {
          hasSubscription = false;
        });
        final selectedAddressId = AddressManager.instance.selectedAddressId;
        await _loadProducts(userId, selectedAddressId);
      }
    } catch (e, stackTrace) {
      // If subscription check fails, fallback to normal product loading
      print('ProductsScreen: Error checking subscription: $e');
      print('ProductsScreen: Stack trace: $stackTrace');

      setState(() {
        hasSubscription = false;
      });
      final selectedAddressId = AddressManager.instance.selectedAddressId;
      await _loadProducts(userId, selectedAddressId);
    }
  }

  Future<void> _loadProducts(String userId, int? addressId) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final result = await ProductService.instance.getProducts(
        userId: userId,
        addressId: addressId,
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
        errorMessage = 'Error loading products. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> _loadAddOns(String userId, int? addressId) async {
    // Add-ons sudah di-hardcode, tidak perlu load dari API

    setState(() {
      isLoading = false;
    });
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
    if (userId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(
              'Processing order...',
              style: TextStyle(fontFamily: 'Open Sans'),
            ),
          ],
        ),
      ),
    );

    try {
      final addressResult = await AddressService.instance.getUserAddresses(
        userId,
      );
      int? selectedAddressId;

      if (addressResult['success'] == true && addressResult['data'] != null) {
        final addresses = addressResult['data'] as List<UserAddress>;
        if (addresses.isNotEmpty) {
          selectedAddressId = addresses.first.addressId;
        }
      }

      final orderRequest = OrderRequest(
        userId: userId,
        productId: product.pid,
        userAddressId: selectedAddressId ?? 1,
        level: '1',
        block: 'A',
        unitNumber: '001',
      );

      final orderResult = await OrderService.instance.createOrder(orderRequest);

      if (mounted) Navigator.of(context).pop();

      if (orderResult['success'] == true) {
        if (mounted) {
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
                    Navigator.of(context).pop();
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
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderResult['message'] ?? 'Failed to create order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToHome() {
    BillService.instance.clearCache(userId: userId);
    ProductService.instance.clearCache(userId: userId);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
      'ProductsScreen: Building widget - isLoading: $isLoading, hasSubscription: $hasSubscription, status: $status',
    );

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const AppBottomNavigation(
          currentRoute: '/products',
        ),
      );
    }

    // Show NotVerifiedWidget if user is not verified
    if (status == 'not_verified') {
      return const NotVerifiedWidget(currentRoute: '/products');
    }

    print(
      'ProductsScreen: Showing main content - hasSubscription: $hasSubscription',
    );

    // Show different content based on subscription status
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
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
                        hintText: hasSubscription
                            ? 'Search Product'
                            : 'Search Products',
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

          // Content - Show different content based on subscription
          Expanded(
            child: hasSubscription
                ? _buildSubscriptionContent()
                : _buildNoSubscriptionContent(),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/products'),
    );
  }

  // Content for users WITH subscription
  Widget _buildSubscriptionContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommended For You - with padding
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: const Text(
              'Recommended For You',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Open Sans',
              ),
            ),
          ),
          const SizedBox(height: 16),

          const BannerSection(),
          const SizedBox(height: 24),

          // Upgrade Care Widget - with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: UpgradeCareWidget(
              currentPlan: currentPlan,
              onUpgradePressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpgradePlanScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Add-ons Section - with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                // HARDCODED Add-ons
                _buildHardcodedAddOn(
                  'HBO GO',
                  'Rp 79,000',
                  'assets/icons/hbo.png',
                ),
                const SizedBox(height: 12),
                _buildHardcodedAddOn(
                  'Netflix Premium',
                  'Rp 186,000',
                  'assets/icons/netflix.png',
                ),
                const SizedBox(height: 12),
                _buildHardcodedAddOn(
                  'Disney+ Hotstar',
                  'Rp 149,000',
                  'assets/icons/disney.png',
                ),
                const SizedBox(height: 12),
                _buildHardcodedAddOn(
                  'Superpack Premium',
                  'Rp 299,000',
                  'assets/icons/superpack.png',
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardcodedAddOn(String title, String price, String iconAsset) {
    return AddOnCardWidget(
      iconAsset: iconAsset,
      title: title,
      price: price,
      onBuyPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title add-on feature coming soon!'),
            backgroundColor: Colors.blue,
          ),
        );
      },
    );
  }

  // Content for users WITHOUT subscription
  Widget _buildNoSubscriptionContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You haven\'t subscribed to any plan yet, explore!',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontFamily: 'Open Sans',
            ),
          ),
          const SizedBox(height: 8),

          // Products Grid
          Expanded(
            child: products.isEmpty && errorMessage.isEmpty
                ? const Center(
                    child: Text(
                      'No products available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  )
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
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final selectedAddressId =
                                AddressManager.instance.selectedAddressId;
                            _loadProducts(userId, selectedAddressId);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductsDetailScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
