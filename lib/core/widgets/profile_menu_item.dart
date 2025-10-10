import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap:
            onTap ??
            () {
              // Placeholder action
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$title clicked')));
            },
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontFamily: 'Open Sans',
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}
