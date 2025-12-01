import 'package:flutter/material.dart';
import 'dart:math';
import '../services/product_service.dart';
import '../services/banner_service.dart' as banner_service;

class ProductCard extends StatefulWidget {
  final Product? product;
  final String? imageUrl;
  final String? title;
  final String? price;
  final VoidCallback? onTap;
  final List<banner_service.Banner>? bannerProductList;

  const ProductCard({
    super.key,
    this.product,
    this.imageUrl,
    this.title,
    this.price,
    this.onTap,
    this.bannerProductList,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late String? _cachedBannerUrl;

  @override
  void initState() {
    super.initState();
    _cachedBannerUrl = _getRandomBannerUrl();
  }

  String? _getRandomBannerUrl() {
    if (widget.bannerProductList == null || widget.bannerProductList!.isEmpty) {
      return null;
    }
    final random = Random();
    final randomBanner = widget
        .bannerProductList![random.nextInt(widget.bannerProductList!.length)];
    return randomBanner.target;
  }

  // Helper getters to prioritize product data over individual params
  String get displayTitle => widget.product?.name ?? widget.title ?? '';
  String get displayPrice =>
      widget.product?.formattedPrice ?? widget.price ?? '';
  String get displayImageUrl => widget.imageUrl ?? '';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 181,
      height: 181,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              width: 165,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildBannerImage(),
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              displayTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontFamily: 'Open Sans',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Divider
            Container(
              height: 1,
              width: double.infinity,
              color: Colors.grey.withOpacity(0.3),
            ),

            const SizedBox(height: 8),

            // Price and Button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price
                Expanded(
                  child: Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ),

                // Choose Button
                GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CB04C),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Text(
                      'Buy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerImage() {
    if (_cachedBannerUrl != null && _cachedBannerUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          _cachedBannerUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.image, color: Colors.grey, size: 32),
            );
          },
        ),
      );
    } else if (displayImageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          displayImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.image, color: Colors.grey, size: 32),
            );
          },
        ),
      );
    } else {
      return const Center(
        child: Icon(Icons.image, color: Colors.grey, size: 32),
      );
    }
  }
}
