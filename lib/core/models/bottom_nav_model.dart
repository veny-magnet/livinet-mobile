import 'package:flutter/material.dart';

class BottomNavModel {
  final String label;
  final IconData icon;
  final String route;
  final bool isActive;

  const BottomNavModel({
    required this.label,
    required this.icon,
    required this.route,
    this.isActive = false,
  });

  BottomNavModel copyWith({
    String? label,
    IconData? icon,
    String? route,
    bool? isActive,
  }) {
    return BottomNavModel(
      label: label ?? this.label,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      isActive: isActive ?? this.isActive,
    );
  }

  static List<BottomNavModel> getNavigationItems() {
    return [
      const BottomNavModel(label: 'Home', icon: Icons.home, route: '/home'),
      const BottomNavModel(
        label: 'Pay',
        icon: Icons.account_balance_wallet,
        route: '/pay',
      ),
      const BottomNavModel(
        label: 'Products',
        icon: Icons.shopping_bag,
        route: '/products',
      ),
      const BottomNavModel(label: 'Help', icon: Icons.help, route: '/help'),
      const BottomNavModel(
        label: 'Profile',
        icon: Icons.person,
        route: '/profile',
      ),
    ];
  }
}
