import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/custom_gradient_header.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/not_verified_widget.dart';
import '../../core/services/user_profile_service.dart';
import 'products_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String status = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      const String defaultUserId = 'CR006000';
      final result = await UserProfileService.instance.getUserProfile(
        defaultUserId,
      );

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          status = data.status ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          status = '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = '';
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

                  const SizedBox(height: 12),

                  // Products Grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          imageUrl: '',
                          title: 'LiviHome Starter Up To 30 Mbps',
                          price: 'Rp 225,000',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProductsDetailScreen(
                                  title: 'LiviHome Starter Up To 30 Mbps',
                                  price: 'Rp 300,000/month',
                                  location:
                                      'Available in Harco Glodok, DKI Jakarta',
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
