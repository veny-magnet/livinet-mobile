import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/bottom_nav_model.dart';

class AppBottomNavigation extends StatelessWidget {
  final String currentRoute;

  const AppBottomNavigation({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final navItems = BottomNavModel.getNavigationItems();

    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.70)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final isActive = currentRoute == item.route;
              return _BottomNavItem(
                item: item.copyWith(isActive: isActive),
                onTap: () => _handleNavigation(context, item.route),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String route) {
    if (currentRoute != route) {
      context.go(route);
    }
  }
}

class _BottomNavItem extends StatelessWidget {
  final BottomNavModel item;
  final VoidCallback onTap;

  const _BottomNavItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = item.isActive;

    // Use theme colors
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                item.icon,
                size: 28,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
