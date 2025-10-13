import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/custom_gradient_header.dart';
import '../../core/widgets/address_selector.dart';
import '../../core/widgets/bill_card.dart';
import '../../core/widgets/quick_action_section.dart';
import '../../core/widgets/points_section.dart';
import '../../core/widgets/banner_section.dart';
import '../../core/services/user_profile_service.dart';
import '../../core/services/bill_service.dart';

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
  Map<String, dynamic>? currentBill;

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
        });

        // Load current bill if user is verified
        if (status == 'verified') {
          await _loadCurrentBill(defaultUserId);
        } else {
          setState(() {
            isLoading = false;
          });
        }
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

  Future<void> _loadCurrentBill(String userId) async {
    try {
      final result = await BillService.instance.getBillHistory(userId: userId);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final bills = data['bills'] as List<dynamic>? ?? [];

        setState(() {
          // Get the latest unpaid bill as current bill
          currentBill = bills.isNotEmpty
              ? bills.firstWhere(
                  (bill) =>
                      bill['status'] == 'pending' || bill['status'] == 'unpaid',
                  orElse: () => bills.first,
                )
              : null;
          isLoading = false;
        });
      } else {
        setState(() {
          currentBill = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        currentBill = null;
        isLoading = false;
      });
      print('Error loading current bill: $e');
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
                      planName:
                          currentBill?['product_name'] ?? 'No Active Plan',
                      billLabel: 'Your Bill',
                      amount: currentBill != null
                          ? 'Rp ${(currentBill!['amount'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
                          : 'Rp 0',
                      status: currentBill?['status'] ?? 'none',
                      onPayPressed: currentBill != null
                          ? () {
                              // Navigate to pay screen instead of creating mock order
                              Navigator.pushNamed(context, '/pay');
                            }
                          : null,
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
