import 'package:flutter/material.dart';
import '../../core/services/product_service.dart';
import '../../core/services/product_detail_service.dart';
import '../../core/services/address_service.dart';
import '../../core/services/user_profile_service.dart';
import '../../core/widgets/order_dialog.dart';

class ProductsDetailScreen extends StatefulWidget {
  final String? title;
  final String? price;
  final String? location;
  final Product? product;

  const ProductsDetailScreen({
    super.key,
    this.title,
    this.price,
    this.location,
    this.product,
  });

  @override
  State<ProductsDetailScreen> createState() => _ProductsDetailScreenState();
}

class _ProductsDetailScreenState extends State<ProductsDetailScreen> {
  bool isLoading = true;
  String errorMessage = '';
  ProductDetail? productDetail;
  String locationText = '';
  String userId = '';

  // Get display values
  String get displayTitle => widget.product?.name ?? widget.title ?? '';
  String get displayPrice =>
      widget.product?.formattedPrice ?? widget.price ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Load all data in parallel to avoid duplicate requests
      await Future.wait([
        _loadUserProfile(),
        if (widget.product != null) _loadProductDetail(widget.product!.pid),
      ]);

      // After userId is available, load location
      if (userId.isNotEmpty) {
        await _loadLocation();
      } else {
        locationText = widget.location ?? 'Location not available';
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading data: $e';
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final result = await UserProfileService.instance.getCurrentUserProfile();

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        // Don't call setState here - will be called once in _loadData
        userId = data.userId ?? '';
      }
    } catch (e) {
      // Silently handle error
    }
  }

  Future<void> _loadLocation() async {
    try {
      if (userId.isEmpty) {
        locationText = widget.location ?? 'Location not available';
        return;
      }

      final result = await AddressService.instance.getUserAddresses(userId);

      if (result['success'] == true && result['data'] != null) {
        final List<UserAddress> addresses = result['data'] as List<UserAddress>;
        if (addresses.isNotEmpty) {
          final address = addresses.first;
          // Don't call setState here - will be called once in _loadData
          locationText =
              'Available in ${address.areaName}, ${address.cityName}, ${address.stateName}';
        } else {
          locationText = widget.location ?? 'Location not available';
        }
      } else {
        locationText = widget.location ?? 'Location not available';
      }
    } catch (e) {
      locationText = widget.location ?? 'Location not available';
    }
  }

  Future<void> _loadProductDetail(int productId) async {
    try {
      final result = await ProductDetailService.instance.getProductDetail(
        productId: productId,
      );

      if (result['success'] == true && result['data'] != null) {
        // Don't call setState here - will be called once in _loadData
        productDetail = result['data'] as ProductDetail;
      }
    } catch (e) {
      // Silently handle error
    }
  }

  void _showOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => OrderDialog(product: widget.product!),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Gradient Header
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4CB04C), Color(0xFFF8D86E)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button and title
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Detail Plan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Product title
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Open Sans',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Price
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location info
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.black,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Plan Description
                  const Text(
                    'Plan Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Open Sans',
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description text or error
                  Expanded(
                    child: SingleChildScrollView(
                      child: errorMessage.isNotEmpty
                          ? Column(
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
                                  onPressed: _loadData,
                                  child: const Text('Retry'),
                                ),
                              ],
                            )
                          : Text(
                              productDetail?.description ??
                                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.black54,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Choose Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.product != null) {
                          _showOrderDialog();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Product information not available',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CB04C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Choose',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
