import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/custom_gradient_header.dart';
import '../../core/widgets/address_selector.dart';
import '../../core/widgets/bill_card.dart';
import '../../core/widgets/quick_action_section.dart';
import '../../core/widgets/points_section.dart';
import '../../core/widgets/banner_section.dart';
import '../../core/widgets/no_plan_widget.dart';
import '../../core/services/user_profile_service.dart';
import '../../core/services/bill_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/address_service.dart';
import '../../core/services/product_service.dart';
import '../../core/models/bill_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String username = 'Loading...';
  String userId = '';
  int points = 0;
  String status = '';
  bool isLoading = true;
  List<BillHistory> billHistory = [];
  String errorMessage = '';
  int? selectedAddressId;
  String currentPlanName = 'Your Current Plan';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh subscription and bill data when app comes back to foreground
      _refreshSubscriptionAndBillData();
    }
  }

  Future<void> _refreshSubscriptionAndBillData() async {
    if (userId.isNotEmpty) {
      try {
        // Force refresh subscription data
        await SubscriptionService.instance.getUserSubscriptions(userId);

        // Force refresh bill data if we have selected address
        if (selectedAddressId != null) {
          final billRequest = BillHistoryRequest(
            userId: userId,
            userAddressId: selectedAddressId!,
          );
          await BillService.instance.getBillHistory(
            billRequest,
            forceRefresh: true,
          );
        }

        // Trigger UI rebuild if needed
        if (mounted) {
          await _loadBillHistory();
        }
      } catch (e) {
        print('Error refreshing data: $e');
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      // Get user data from auth service or current session
      final result = await UserProfileService.instance.getCurrentUserProfile();

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          username = data.username ?? 'User';
          userId = data.userId ?? '';
          points = data.points ?? 0;
          status = data.status ?? '';
          isLoading = false;
        });

        // Load bill history if user is verified and has userId
        if (status == 'verified' && userId.isNotEmpty) {
          await _loadBillHistory();
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

  Future<void> _loadBillHistory() async {
    try {
      if (userId.isEmpty) {
        setState(() {
          errorMessage = 'User ID not available';
        });
        return;
      }

      final addressResult = await AddressService.instance.getUserAddresses(
        userId,
      );

      if (addressResult['success'] == true && addressResult['data'] != null) {
        final List<UserAddress> addresses =
            addressResult['data'] as List<UserAddress>;
        if (addresses.isNotEmpty) {
          selectedAddressId = addresses.first.addressId;

          // Get bill history
          final billRequest = BillHistoryRequest(
            userId: userId,
            userAddressId: selectedAddressId!,
          );

          final result = await BillService.instance.getBillHistory(billRequest);

          if (result['success'] == true && result['data'] != null) {
            setState(() {
              billHistory = result['data'] as List<BillHistory>;
            });

            // Load product name after getting bill history
            await _loadCurrentPlanName();
          } else {
            // Fallback to subscription service if bill history fails
            print('Bill history failed, trying subscription service...');
            try {
              final subscriptionResult = await SubscriptionService.instance
                  .getUserSubscriptions(userId);
              if (subscriptionResult['success'] == true &&
                  subscriptionResult['data'] != null) {
                final subscriptionBills = SubscriptionService.instance
                    .convertSubscriptionsToBills(
                      subscriptionResult['data'] as Map<String, dynamic>,
                    );
                setState(() {
                  billHistory = subscriptionBills;
                });
              } else {
                setState(() {
                  errorMessage =
                      result['message'] ??
                      'Failed to load bill history and subscriptions';
                });
              }
            } catch (e) {
              setState(() {
                errorMessage = 'Error loading data: $e';
              });
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading bill history: $e';
      });
      print('Error loading bill history: $e');
    }
  }

  Future<void> _loadCurrentPlanName() async {
    try {
      if (userId.isNotEmpty && selectedAddressId != null) {
        print('HomeScreen: Loading subscription data for userId: $userId');

        // Get subscription data to find the current plan name
        final subscriptionResult = await SubscriptionService.instance
            .getUserSubscriptions(userId);

        print('HomeScreen: Subscription API response: $subscriptionResult');

        if (subscriptionResult['success'] == true &&
            subscriptionResult['data'] != null) {
          final subscriptionData =
              subscriptionResult['data'] as Map<String, dynamic>;

          print('HomeScreen: Subscription data: $subscriptionData');

          final subscriptions =
              subscriptionData['subscriptions'] as List<dynamic>? ?? [];

          print('HomeScreen: Found ${subscriptions.length} subscriptions');

          if (subscriptions.isNotEmpty) {
            final currentSubscription = subscriptions.first;
            print(
              'HomeScreen: Current subscription details: $currentSubscription',
            );

            // Priority: use subsplanName from subscription response
            final planName =
                currentSubscription['subsplanName']?.toString() ??
                currentSubscription['productDescription']?.toString() ??
                currentSubscription['plan_name']?.toString() ??
                currentSubscription['name']?.toString();

            print('HomeScreen: Extracted plan name: $planName');

            if (planName != null && planName.isNotEmpty) {
              setState(() {
                currentPlanName = planName;
              });
              print(
                'HomeScreen: Updated plan name from subscription to: $planName',
              );
              return;
            } else {
              print(
                'HomeScreen: No valid plan name found in subscription data',
              );
            }
          } else {
            print('HomeScreen: No subscriptions found in response');
          }
        } else {
          print('HomeScreen: Subscription API failed or returned no data');
          print('HomeScreen: Success: ${subscriptionResult['success']}');
          print('HomeScreen: Message: ${subscriptionResult['message']}');
        }

        // Fallback: Get product name via ProductService (only if subscription fails)
        final products = await ProductService.instance.getProductsForAddress(
          userId: userId,
          addressId: selectedAddressId!,
        );

        if (products['success'] == true && products['data'] != null) {
          final productList = products['data'] as List<Product>;
          if (productList.isNotEmpty) {
            setState(() {
              currentPlanName = productList.first.name;
            });
            print(
              'Updated plan name from products to: ${productList.first.name}',
            );
          }
        }
      }
    } catch (e) {
      print('Error loading current plan name: $e');
      // Keep default name if error occurs
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
                      userId: userId.isNotEmpty ? userId : '',
                      defaultAddress: '',
                      onAddressSelected: (selectedAddress) {
                        print(
                          'Address selected: ${selectedAddress.formattedAddress}',
                        );
                        // TODO: Update bill or other components based on selected address
                      },
                    ),

                    const SizedBox(height: 16),

                    // Show different BillCard based on bill history
                    billHistory.isEmpty
                        ? const NoPlanWidget()
                        : BillCard(
                            planName: currentPlanName,
                            billLabel: 'Your Bill',
                            amount: billHistory.any((bill) => !bill.isPaid)
                                ? billHistory
                                      .firstWhere((bill) => !bill.isPaid)
                                      .formattedAmount
                                : billHistory.isNotEmpty
                                ? billHistory.first.formattedAmount
                                : 'Rp 0',
                            status: billHistory.any((bill) => !bill.isPaid)
                                ? 'UNPAID'
                                : 'PAID',
                            billData: billHistory.any((bill) => !bill.isPaid)
                                ? billHistory.firstWhere((bill) => !bill.isPaid)
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
