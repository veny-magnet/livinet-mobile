import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/custom_gradient_header.dart';
import '../../core/widgets/address_selector.dart';
import '../../core/widgets/bill_card.dart';
import '../../core/widgets/quick_action_section.dart';
import '../../core/widgets/points_section.dart';
import '../../core/widgets/banner_section.dart';
import '../../core/services/user_profile_service.dart';
import '../payment/payment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = 'Loading...';
  String userId = '';
  int points = 0;
  String status = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // For now, using a default user ID - you can get this from SharedPreferences or auth service
      const String defaultUserId = 'CR006000';

      final result = await UserProfileService.instance.getUserProfile(
        defaultUserId,
      );

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          username = data.username ?? 'User';
          userId = data.userId ?? '';
          points = data.points ?? 0;
          status = data.status ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          username = 'User';
          userId = '';
          points = 0;
          status = '';
          isLoading = false;
        });
        print('Failed to load profile: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        username = 'User';
        userId = '';
        points = 0;
        status = '';
        isLoading = false;
      });
      print('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomGradientHeader(
                title: '',
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoading ? 'Loading...' : username,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                            if (!isLoading) ...[
                              if (status == 'not_verified')
                                Text(
                                  'Waiting for admin verification',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFDC6E6E),
                                    fontFamily: 'Open Sans',
                                  ),
                                )
                              else if (status == 'verified' &&
                                  userId.isNotEmpty)
                                Text(
                                  userId,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                    fontFamily: 'Open Sans',
                                  ),
                                ),
                            ] else
                              Text(
                                '...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Show AddressSelector and BillCard only if user is verified
                  if (status == 'verified') ...[
                    AddressSelector(
                      userId: userId.isNotEmpty ? userId : 'CR006000',
                      defaultAddress: 'Apartemen Mediterania Lt. 31 Unit 32AN',
                      onAddressSelected: (selectedAddress) {
                        print(
                          'Address selected: ${selectedAddress.formattedAddress}',
                        );
                        // TODO: Update bill or other components based on selected address
                      },
                    ),

                    const SizedBox(height: 16),

                    BillCard(
                      planName: 'LiviHome Premium',
                      billLabel: 'Your Bill',
                      amount: 'Rp 225,000',
                      lastPaymentDate: '05 September 2025',
                      onPayPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentScreen(
                              planName: 'LiviPro Superfast',
                              amount: 'Rp 225,000',
                              billNumber: '23989021890',
                              period: '(01-08-2025 to 31/08/2025)',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Quick Action
              const QuickActionSection(),

              const SizedBox(height: 24),

              // Your Points - only show if user is verified
              if (status == 'verified') PointsSection(points: points),

              if (status == 'verified') const SizedBox(height: 24),

              // Recommended For You
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended For You',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              const BannerSection(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/home'),
    );
  }
}
