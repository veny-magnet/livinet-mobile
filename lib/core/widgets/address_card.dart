import 'package:flutter/material.dart';
import '../services/address_service.dart';

class AddressCard extends StatelessWidget {
  final UserAddress address;
  final VoidCallback onDetailTap;

  const AddressCard({
    super.key,
    required this.address,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Location Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.grey,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Address Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Area name (title)
                  Text(
                    address.areaName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Open Sans',
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Full address
                  Text(
                    '${address.address}, ${address.cityName}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'Open Sans',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Detail Button
            InkWell(
              onTap: onDetailTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4CB04C)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Detail',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4CB04C),
                    fontFamily: 'Open Sans',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
