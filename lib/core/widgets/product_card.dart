import 'package:flutter/material.dart';
import '../services/product_service.dart';

class ProductCard extends StatelessWidget {
  final Product? product;
  final String? imageUrl;
  final String? title;
  final String? price;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    this.product,
    this.imageUrl,
    this.title,
    this.price,
    this.onTap,
  });

  // Helper getters to prioritize product data over individual params
  String get displayTitle => product?.name ?? title ?? '';
  String get displayPrice => product?.formattedPrice ?? price ?? '';
  String get displayImageUrl => imageUrl ?? '';

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
              child: displayImageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        displayImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 32,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, color: Colors.grey, size: 32),
                    ),
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
                  onTap: onTap,
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
}
