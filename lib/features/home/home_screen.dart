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
import '../../core/services/order_details_service.dart';
import '../../core/models/bill_models.dart';
import '../../core/models/order_detail_models.dart' as order_detail;

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
  order_detail.OrderDetailsResponse? orderDetailsData;
  order_detail.OrderDetail? currentOrderDetail;
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
        // Priority 1: Try OrderDetails first
        if (selectedAddressId != null) {
          final orderDetailsService = OrderDetailsService.instance;
          await orderDetailsService.getOrderDetails(
            userId: userId,
            userAddressId: selectedAddressId!,
            forceRefresh: true,
          );
        }

        // Fallback: Force refresh subscription data
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
      } catch (e) {}
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get user data from auth service or current session
      final result = await UserProfileService.instance.getCurrentUserProfile();

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        // Don't call setState here - will be called once at the end
        username = data.username ?? 'User';
        userId = data.userId ?? '';
        points = data.points ?? 0;
        status = data.status ?? '';

        // Load bill history if user is verified and has userId
        if (status == 'verified' && userId.isNotEmpty) {
          await _loadBillHistory();
        }

        setState(() {
          isLoading = false;
        });
      } else {
        username = 'User';
        userId = '';
        points = 0;
        status = '';
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      username = 'User';
      userId = '';
      points = 0;
      status = '';
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadBillHistory() async {
    try {
      if (userId.isEmpty) {
        errorMessage = 'User ID not available';
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

          // PRIORITY 1: Try OrderDetails API first
          final orderDetailsService = OrderDetailsService.instance;
          final orderDetailsResponse = await orderDetailsService
              .getOrderDetails(
                userId: userId,
                userAddressId: selectedAddressId!,
              );

          if (orderDetailsResponse != null &&
              orderDetailsResponse.orders.isNotEmpty) {
            // Don't call setState here - will be called once in _loadUserProfile
            orderDetailsData = orderDetailsResponse;
            currentOrderDetail = orderDetailsResponse.orders.first;
            // Convert OrderDetail to BillHistory for backward compatibility if needed
            billHistory = _convertOrderDetailsToBillHistory(
              orderDetailsResponse.orders,
            );
            await _loadCurrentPlanName();
            return;
          }

          // PRIORITY 2: Try BillHistory API
          final billRequest = BillHistoryRequest(
            userId: userId,
            userAddressId: selectedAddressId!,
          );

          final result = await BillService.instance.getBillHistory(billRequest);

          if (result['success'] == true && result['data'] != null) {
            // Don't call setState here - will be called once in _loadUserProfile
            billHistory = result['data'] as List<BillHistory>;

            // Load product name after getting bill history
            await _loadCurrentPlanName();
          } else {
            try {
              final subscriptionResult = await SubscriptionService.instance
                  .getUserSubscriptions(userId);
              if (subscriptionResult['success'] == true &&
                  subscriptionResult['data'] != null) {
                final subscriptionBills = SubscriptionService.instance
                    .convertSubscriptionsToBills(
                      subscriptionResult['data'] as Map<String, dynamic>,
                    );
                billHistory = subscriptionBills;
              } else {
                errorMessage =
                    result['message'] ??
                    'Failed to load bill history and subscriptions';
              }
            } catch (e) {
              errorMessage = 'Error loading data: $e';
            }
          }
        }
      }
    } catch (e) {
      errorMessage = 'Error loading bill history: $e';
    }
  }

  /// Convert OrderDetails to BillHistory for backward compatibility
  List<BillHistory> _convertOrderDetailsToBillHistory(
    List<order_detail.OrderDetail> orders,
  ) {
    return orders.map((order) {
      return BillHistory(
        amount: order.invoiceAmount,
        paymentStatus: order.statusData.isPaid ? 'paid' : 'unpaid',
        invoiceStatusWhmcs: order.invoiceStatus.toLowerCase(),
        paymentDate: order.statusData.isPaid ? order.createdAt : null,
        invoiceId: order.whmcsOrderId.toString(),
        midtransOrderId: order.midtransData.midtransOrderId,
        userAddressId: order.addressDetails.addressId,
        createdAt: order.createdAt,
      );
    }).toList();
  }

  Future<void> _loadCurrentPlanName() async {
    try {
      if (userId.isNotEmpty && selectedAddressId != null) {
        if (currentOrderDetail != null) {
          final planName =
              currentOrderDetail!.productData.subsplanName.isNotEmpty
              ? currentOrderDetail!.productData.subsplanName
              : currentOrderDetail!.productData.productName.isNotEmpty
              ? currentOrderDetail!.productData.productName
              : currentOrderDetail!.serviceName;

          if (planName.isNotEmpty) {
            // Don't call setState here - will be called once in _loadUserProfile
            currentPlanName = planName;
            return;
          }
        }

        // PRIORITY 2: Fallback to subscription service

        final subscriptionResult = await SubscriptionService.instance
            .getUserSubscriptions(userId);

        if (subscriptionResult['success'] == true &&
            subscriptionResult['data'] != null) {
          final subscriptionData =
              subscriptionResult['data'] as Map<String, dynamic>;

          final subscriptions =
              subscriptionData['subscriptions'] as List<dynamic>? ?? [];

          if (subscriptions.isNotEmpty) {
            final currentSubscription = subscriptions.first;

            // Priority: use subsplanName from subscription response
            final planName =
                currentSubscription['subsplanName']?.toString() ??
                currentSubscription['productDescription']?.toString() ??
                currentSubscription['plan_name']?.toString() ??
                currentSubscription['name']?.toString();

            if (planName != null && planName.isNotEmpty) {
              // Don't call setState here - will be called once in _loadUserProfile
              currentPlanName = planName;
              return;
            }
          }
        }

        // PRIORITY 3: Final fallback - Get product name via ProductService
        final products = await ProductService.instance.getProductsForAddress(
          userId: userId,
          addressId: selectedAddressId!,
        );

        if (products['success'] == true && products['data'] != null) {
          final productList = products['data'] as List<Product>;
          if (productList.isNotEmpty) {
            // Don't call setState here - will be called once in _loadUserProfile
            currentPlanName = productList.first.name;
          }
        }
      }
    } catch (e) {
      // Ignore errors in loading plan name
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
                      onAddressSelected: (selectedAddress) async {
                        setState(() {
                          selectedAddressId = selectedAddress.addressId;
                        });

                        // Reload bill history dengan address yang baru dipilih
                        await _loadBillHistory();
                      },
                    ),

                    const SizedBox(height: 16),

                    // Show different BillCard based on available data
                    (billHistory.isEmpty && currentOrderDetail == null)
                        ? const NoPlanWidget()
                        : currentOrderDetail != null
                        ? BillCard.fromOrderDetail(
                            orderDetail: currentOrderDetail!,
                            userId: userId,
                            userAddressId: selectedAddressId,
                          )
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
                            useOrderDetails: true,
                            userId: userId,
                            userAddressId: selectedAddressId,
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
