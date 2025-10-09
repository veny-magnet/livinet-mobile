import 'package:flutter/material.dart';
import 'profile_menu_item.dart';

class ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> menuItems;

  const ProfileMenuSection({
    super.key,
    required this.title,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Open Sans',
            ),
          ),
          const SizedBox(height: 12),
          ...menuItems
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProfileMenuItem(
                    icon: item['icon'] as IconData,
                    title: item['title'] as String,
                    onTap: item['onTap'] as VoidCallback?,
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
