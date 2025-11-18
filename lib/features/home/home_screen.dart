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
import '../../core/services/address_service.dart';
import '../../core/services/order_details_service.dart';
import '../../core/services/ktp_service.dart';
import '../../core/services/address_manager.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/order_detail_models.dart' as order_detail;

class HomeScreen extends StatefulWidget {
  final bool shouldRefresh;

  const HomeScreen({super.key, this.shouldRefresh = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String username = 'Loading...';
  String userId = '';
  String userCode = ''; // UUID from login
  int points = 0;
  String status = '';
  bool isLoading = true;
  bool _isLoadingProfile = false;
  bool _hasRefreshed = false;
  bool hasKtpData = false;
  order_detail.OrderDetailsResponse? orderDetailsData;
  order_detail.OrderDetail? currentOrderDetail;
  String errorMessage = '';
  String? selectedAddressCode;
  String currentPlanName = 'Your Current Plan';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load user profile directly (no cache assumption)
    _loadUserProfile();

    // Handle shouldRefresh flag on first frame only
    if (widget.shouldRefresh && !_hasRefreshed) {
      _hasRefreshed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadUserProfile();
        }
      });
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only refresh once when shouldRefresh changes from false to true
    if (widget.shouldRefresh && !oldWidget.shouldRefresh && !_hasRefreshed) {
      _hasRefreshed = true;
      _loadUserProfile();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _loadUserProfile() async {
    // Prevent multiple concurrent loads
    if (_isLoadingProfile) return;

    _isLoadingProfile = true;
    setState(() {
      isLoading = true;
    });

    try {
      // First, get current user to get code
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();

      if (currentUser == null || currentUser['code'] == null) {
        username = 'User';
        userId = '';
        points = 0;
        status = '';
        hasKtpData = false;
        setState(() {
          isLoading = false;
        });
        return;
      }

      String userCode = currentUser['code'];

      // Get KTP data first
      final ktpResult = await KtpService().getKtpData(userCode: userCode);
      if (ktpResult['success'] == true && ktpResult['data'] != null) {
        hasKtpData = true;
      } else {
        hasKtpData = false;
      }

      // Then get user profile
      final result = await UserProfileService.instance.getCurrentUserProfile();

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        username = data.username ?? 'User';
        userId = data.userId ?? '';
        points = data.points ?? 0;
        status = data.status ?? '';

        // Store userCode state for later use
        this.userCode = userCode;

        // Load bill history only if user is verified and has userCode
        if (status == 'verified' && userCode.isNotEmpty) {
          await _loadOrderDetails(userCode);
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
      hasKtpData = false;
      setState(() {
        isLoading = false;
      });
    } finally {
      _isLoadingProfile = false;
    }
  }

  Future<void> _loadOrderDetails(String userCode, {String? addressCode}) async {
    try {
      if (userCode.isEmpty) {
        errorMessage = 'User code not available';
        return;
      }

      // If no specific address code provided, load addresses first
      if (addressCode == null) {
        final addressResult = await AddressService.instance.getUserAddresses(
          userCode,
        );

        if (addressResult['success'] == true && addressResult['data'] != null) {
          final List<UserAddress> addresses =
              addressResult['data'] as List<UserAddress>;
          if (addresses.isNotEmpty) {
            final firstAddress = addresses.first;
            selectedAddressCode = firstAddress.code;
            AddressManager.instance.setSelectedAddress(firstAddress);
            addressCode = firstAddress.code;
          }
        }
      }

      // Load OrderDetails with the determined address code
      if (addressCode != null && addressCode.isNotEmpty) {
        final orderDetailsResponse = await OrderDetailsService.instance
            .getOrderDetails(userId: userCode, userAddressId: addressCode);

        // Use OrderDetails if available
        if (orderDetailsResponse != null &&
            orderDetailsResponse.orders.isNotEmpty) {
          setState(() {
            orderDetailsData = orderDetailsResponse;
            currentOrderDetail = orderDetailsResponse.orders.first;
          });
          await _loadCurrentPlanName();
        } else {
          setState(() {
            currentOrderDetail = null;
            orderDetailsData = null;
          });
        }
      }
    } catch (e) {
      errorMessage = 'Error loading order details: $e';
    }
  }

  Future<void> _loadCurrentPlanName() async {
    try {
      if (userCode.isNotEmpty && selectedAddressCode != null) {
        // Check if we already have plan name from currentOrderDetail
        if (currentOrderDetail != null) {
          final planName =
              currentOrderDetail!.productData.subsplanName.isNotEmpty
              ? currentOrderDetail!.productData.subsplanName
              : currentOrderDetail!.productData.productName.isNotEmpty
              ? currentOrderDetail!.productData.productName
              : currentOrderDetail!.serviceName;

          if (planName.isNotEmpty) {
            currentPlanName = planName;
            return;
          }
        }

        // If all else fails, use default
        currentPlanName = 'Your Current Plan';
      }
    } catch (e) {
      // Ignore errors in loading plan name
      currentPlanName = 'Your Current Plan';
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
                            const SizedBox(height: 6),
                            if (!isLoading) ...[
                              if (!hasKtpData)
                                Text(
                                  'Upload ID Card to activate your account',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFDC6E6E),
                                    fontFamily: 'Open Sans',
                                  ),
                                )
                              else if (status == 'not_verified')
                                Text(
                                  'Waiting for admin verification',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                      userCode: userCode.isNotEmpty ? userCode : '',
                      defaultAddress: '',
                      onAddressSelected: (selectedAddress) async {
                        setState(() {
                          selectedAddressCode = selectedAddress.code;
                        });

                        // Load only OrderDetails for the selected address
                        await _loadOrderDetails(
                          userCode,
                          addressCode: selectedAddress.code,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    currentOrderDetail != null
                        ? BillCard.fromOrderDetail(
                            orderDetail: currentOrderDetail!,
                            userId: userCode,
                            userAddressId: selectedAddressCode,
                          )
                        : const NoPlanWidget(),
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
