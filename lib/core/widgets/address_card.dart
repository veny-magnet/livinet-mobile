import 'package:flutter/material.dart';
import '../services/address_service.dart';

class AddressCard extends StatelessWidget {
  final UserAddress address;
  final VoidCallback onDetailTap;
  final VoidCallback? onDeleteTap;

  const AddressCard({
    super.key,
    required this.address,
    required this.onDetailTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: State Name + Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // State Name (Main Title)
                Expanded(
                  child: Text(
                    address.areaName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ),

                // Action Buttons
                Row(
                  children: [
                    // Edit/Detail Button
                    InkWell(
                      onTap: onDetailTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CB04C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF4CB04C),
                          size: 18,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Delete Button
                    if (onDeleteTap != null)
                      InkWell(
                        onTap: onDeleteTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CB04C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFF4CB04C),
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Address Details
            Text(
              '${address.address}, ${address.cityName}, ${address.stateName}, ${address.postcode}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'Open Sans',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
