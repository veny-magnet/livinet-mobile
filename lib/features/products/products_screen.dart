import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/custom_gradient_header.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/not_verified_widget.dart';
import '../../core/services/user_profile_service.dart';
import '../../core/services/product_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/address_manager.dart';
import '../../core/services/address_service.dart';
import 'products_detail_screen.dart';
import 'products_after_subscription_screen.dart';

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
  String errorMessage = '';

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
    // This ensures we don't get stale cached data
    if (status == 'verified' && userId.isNotEmpty) {
      // Force clear product cache for this user to prevent stale data
      ProductService.instance.clearCache(userId: userId);

      // Add small delay to ensure cache is cleared before loading
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _loadProducts(userId, address?.addressId);
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
      final subscriptionResult = await SubscriptionService.instance
          .getUserSubscriptions(userId);

      if (subscriptionResult['success'] == true &&
          subscriptionResult['data'] != null &&
          subscriptionResult['data']['subscriptions'] != null &&
          (subscriptionResult['data']['subscriptions'] as List).isNotEmpty) {
        // User has subscription, navigate to after subscription screen
        final subscriptions =
            subscriptionResult['data']['subscriptions'] as List;
        final currentPlan =
            subscriptions.first['subsplanName']?.toString() ??
            subscriptions.first['productDescription']?.toString() ??
            'Current Plan';

        print('ProductsScreen: Found subscription plan: $currentPlan');

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  ProductsAfterSubscriptionScreen(currentPlan: currentPlan),
            ),
          );
        }
      } else {
        // No subscription, load products normally
        final selectedAddressId = AddressManager.instance.selectedAddressId;
        await _loadProducts(userId, selectedAddressId);
      }
    } catch (e) {
      // If subscription check fails, fallback to normal product loading
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

  @override
  Widget build(BuildContext context) {
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

    // Normal Products screen for verified users
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
                        hintText: 'Search Products',
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

          // Products Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header text
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
                                    final selectedAddressId = AddressManager
                                        .instance
                                        .selectedAddressId;
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
                                          ProductsDetailScreen(
                                            product: product,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
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
