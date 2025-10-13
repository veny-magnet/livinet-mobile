import 'package:flutter/material.dart';
import '../../core/services/product_service.dart';
import '../../core/services/product_detail_service.dart';
import '../../core/services/address_service.dart';
import '../../core/services/address_manager.dart';
import '../../core/services/order_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/unit_info_dialog.dart';
import '../../core/models/order_summary.dart';
import '../payment/payment_screen.dart';

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
  bool isOrdering = false;
  ProductDetail? productDetail;
  String locationText = '';
  String? _cachedUserId;

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
      await _loadLocation();

      final product = widget.product;
      if (product != null) {
        await _loadProductDetail(product.pid);
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading data: $e';
      });
    }
  }

  Future<void> _loadLocation() async {
    try {
      final userId = await _resolveUserId();
      final manager = AddressManager.instance;

      if (manager.selectedAddress != null) {
        final address = manager.selectedAddress!;
        if (mounted) {
          setState(() {
            locationText =
                'Available in ${address.areaName}, ${address.cityName}, ${address.stateName}';
          });
        }
        return;
      }

      final cachedAddresses = AddressService.instance.getCachedAddresses(
        userId,
      );
      if (cachedAddresses != null && cachedAddresses.isNotEmpty) {
        manager.setSelectedAddress(cachedAddresses.first);
        if (mounted) {
          setState(() {
            locationText =
                'Available in ${cachedAddresses.first.areaName}, ${cachedAddresses.first.cityName}, ${cachedAddresses.first.stateName}';
          });
        }
        return;
      }

      final result = await AddressService.instance.getUserAddresses(userId);
      if (result['success'] == true && result['data'] != null) {
        final List<UserAddress> addresses = result['data'] as List<UserAddress>;
        if (addresses.isNotEmpty) {
          manager.setSelectedAddress(addresses.first);
          if (mounted) {
            setState(() {
              locationText =
                  'Available in ${addresses.first.areaName}, ${addresses.first.cityName}, ${addresses.first.stateName}';
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          locationText = widget.location ?? 'Location not available';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          locationText = widget.location ?? 'Location not available';
        });
      }
    }
  }

  Future<void> _loadProductDetail(int productId) async {
    try {
      final result = await ProductDetailService.instance.getProductDetail(
        productId: productId,
      );

      if (result['success'] == true && result['data'] != null) {
        if (mounted) {
          setState(() {
            productDetail = result['data'] as ProductDetail;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading product detail: $e');
    }
  }

  Future<String> _resolveUserId() async {
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
      return _cachedUserId!;
    }

    final authService = AuthService();
    final currentUser = await authService.getCurrentUser();
    final resolvedId = _extractUserId(currentUser) ?? 'CR006000';
    _cachedUserId = resolvedId;
    return resolvedId;
  }

  String? _extractUserId(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }

    final directKeys = ['user_id', 'userId', 'userid'];
    for (final key in directKeys) {
      final value = data[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    if (data['user'] is Map<String, dynamic>) {
      final userMap = data['user'] as Map<String, dynamic>;
      final value = userMap['user_id'] ?? userMap['userId'] ?? userMap['id'];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    if (data['data'] is Map<String, dynamic>) {
      final nested = data['data'] as Map<String, dynamic>;
      final value =
          nested['user_id'] ??
          nested['userId'] ??
          nested['userid'] ??
          nested['id'];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
  }

  Future<void> _handleUnitSelection() async {
    String? level;
    String? block;
    String? unitNumber;

    await showUnitInfoDialog(
      context,
      onConfirm: (selectedLevel, selectedBlock, selectedUnit) {
        level = selectedLevel;
        block = selectedBlock;
        unitNumber = selectedUnit;
      },
    );

    if (!mounted) {
      return;
    }

    if (level == null || block == null || unitNumber == null) {
      return;
    }

    await _createOrder(level!, block!, unitNumber!);
  }

  Future<void> _createOrder(
    String level,
    String block,
    String unitNumber,
  ) async {
    if (isOrdering) {
      return;
    }

    final productId = _resolveProductId();
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product ID tidak ditemukan.')),
      );
      return;
    }

    setState(() {
      isOrdering = true;
    });

    try {
      final userId = await _resolveUserId();
      final addressId = await _resolveAddressId(userId);

      if (addressId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alamat tidak tersedia.')),
          );
        }
        return;
      }

      final result = await OrderService.instance.createOrder(
        userId: userId,
        productId: productId,
        userAddressId: addressId,
        level: level,
        block: block,
        unitNumber: unitNumber,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true && result['data'] is OrderSummary) {
        final summary = result['data'] as OrderSummary;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(orderSummary: summary),
          ),
        );
      } else {
        final message = result['message']?.toString() ?? 'Gagal membuat order.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isOrdering = false;
        });
      }
    }
  }

  int? _resolveProductId() {
    if (widget.product != null) {
      return widget.product!.pid;
    }

    final raw = productDetail?.rawData ?? {};
    final possibleKeys = ['pid', 'product_id', 'id'];
    for (final key in possibleKeys) {
      final value = raw[key];
      if (value is int) {
        return value;
      }
      if (value != null) {
        final parsed = int.tryParse(value.toString());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  Future<int?> _resolveAddressId(String userId) async {
    final manager = AddressManager.instance;
    if (manager.selectedAddressId != null) {
      return manager.selectedAddressId;
    }

    final cachedAddresses = AddressService.instance.getCachedAddresses(userId);
    if (cachedAddresses != null && cachedAddresses.isNotEmpty) {
      manager.setSelectedAddress(cachedAddresses.first);
      return cachedAddresses.first.addressId;
    }

    final result = await AddressService.instance.getUserAddresses(userId);
    if (result['success'] == true && result['data'] != null) {
      final List<UserAddress> addresses = result['data'] as List<UserAddress>;
      if (addresses.isNotEmpty) {
        manager.setSelectedAddress(addresses.first);
        return addresses.first.addressId;
      }
    }

    return null;
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
                      onPressed: isOrdering ? null : _handleUnitSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CB04C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: isOrdering
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
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
