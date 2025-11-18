import 'package:flutter/material.dart';
import '../services/address_service.dart';
import '../../features/profile/address_detail_screen.dart';

class AddressCard extends StatelessWidget {
  final UserAddress address;
  final List<dynamic>? subscriptions;
  final VoidCallback onDetailTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onAddressDeleted;

  const AddressCard({
    super.key,
    required this.address,
    this.subscriptions,
    required this.onDetailTap,
    this.onDeleteTap,
    this.onAddressDeleted,
  });

  // Get subscription for this address
  Map<String, dynamic>? _getSubscriptionForAddress() {
    if (subscriptions == null || subscriptions!.isEmpty) return null;

    try {
      return subscriptions!.firstWhere(
        (sub) => sub['address']?['code'] == address.code,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = _getSubscriptionForAddress();
    final hasSubscription = subscription != null;
    final productName = subscription?['subsplanName']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Icon
          Container(
            width: 40,
            height: 40,
            child: Icon(
              Icons.location_on_sharp,
              color: Colors.grey.shade700,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CB04C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddressDetailScreen(
                                address: address,
                                onAddressDeleted: onAddressDeleted,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Address Details
                Text(
                  '${address.address}, ${address.cityName}, ${address.stateName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'Open Sans',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Subscription Badges
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Always show subscription status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hasSubscription ? 'Subscribed' : 'No Subscription',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ),
                    // Show product name badge only if subscription exists
                    if (productName != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF4CB04C),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          productName,
                          style: const TextStyle(
                            color: Color(0xFF4CB04C),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
