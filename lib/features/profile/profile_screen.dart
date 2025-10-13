import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/profile_header.dart';
import '../../core/widgets/profile_menu_section.dart';
import '../../core/widgets/not_verified_widget.dart';
import '../../core/services/user_profile_service.dart';
import '../../core/services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'address_screen.dart';
import 'change-password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String status = '';
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // First try to get cached profile to get user ID
      final cachedProfile = UserProfileService.instance.getCachedProfile();

      String? userIdToUse;

      if (cachedProfile != null) {
        userIdToUse = cachedProfile.userId;
      } else {
        // Get user ID from auth service
        final authService = AuthService();
        final currentUser = await authService.getCurrentUser();

        if (currentUser != null && currentUser['user_id'] != null) {
          userIdToUse = currentUser['user_id'];
        } else {
          // If no user found in auth, user needs to login
          setState(() {
            status = 'not_logged_in';
            isLoading = false;
          });
          return;
        }
      }

      final result = await UserProfileService.instance.getUserProfile(
        userIdToUse!,
      );

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          status = data.status ?? '';
          userId = data.userId ?? userIdToUse;
          isLoading = false;
        });
      } else {
        setState(() {
          status = '';
          userId = userIdToUse;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = 'error';
        userId = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const AppBottomNavigation(
          currentRoute: '/profile',
        ),
      );
    }

    // Show NotVerifiedWidget if user is not verified
    if (status == 'not_verified') {
      return const NotVerifiedWidget(currentRoute: '/profile');
    }

    // Account menu items
    final accountMenuItems = [
      {
        'icon': Icons.location_on_outlined,
        'title': 'Address',
        'onTap': () {
          if (userId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddressScreen(userId: userId!),
              ),
            );
          }
        },
      },
      {
        'icon': Icons.person_outline,
        'title': 'Edit Profile',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
          );
        },
      },
      {
        'icon': Icons.lock_outline,
        'title': 'Change Password',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangePasswordScreen(),
            ),
          );
        },
      },
      {'icon': Icons.emoji_events_outlined, 'title': 'Points', 'onTap': null},
    ];

    // Other menu items
    final otherMenuItems = [
      {'icon': Icons.help_outline, 'title': 'Help', 'onTap': null},
      {
        'icon': Icons.router_rounded,
        'title': 'Service and Device Information',
        'onTap': null,
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Terms and Conditions',
        'onTap': null,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Profile Header
          const ProfileHeader(),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Account Section
                  ProfileMenuSection(
                    title: 'Account',
                    menuItems: accountMenuItems,
                  ),

                  const SizedBox(height: 24),

                  // Other Section
                  ProfileMenuSection(title: 'Other', menuItems: otherMenuItems),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/profile'),
    );
  }
}
