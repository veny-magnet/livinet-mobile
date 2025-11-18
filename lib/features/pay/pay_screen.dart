import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/bill_card.dart';
import '../../core/widgets/custom_gradient_header.dart';
import '../../core/widgets/not_verified_widget.dart';
import '../../core/widgets/no_plan_widget.dart';
import '../../core/services/user_profile_service.dart';
import '../../core/services/bill_service.dart';
import 'bill_detail_screen.dart';
import '../../core/services/address_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/order_details_service.dart';
import '../../core/services/address_manager.dart';
import '../../core/models/bill_models.dart';
import '../../core/models/order_detail_models.dart' as order_detail;

class PayScreen extends StatefulWidget {
  const PayScreen({super.key});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  String status = '';
  String userId = '';
  String userCode = ''; // UUID dari login
  bool isLoading = true;
  List<BillHistory> billHistory = [];
  order_detail.OrderDetailsResponse? orderDetailsData;
  order_detail.OrderDetail? currentOrderDetail;
  String errorMessage = '';
  String? selectedAddressCode;
  String currentPlanName = '';

  DateTime? _lastLoadTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  String? _lastLoadedAddressId;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Listen to address changes from AddressManager
    AddressManager.instance.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    // Remove listener when screen is disposed
    AddressManager.instance.removeListener(_onAddressChanged);
    super.dispose();
  }

  void _onAddressChanged(UserAddress? address) {
    // When address changes, reload bill history for the new address
    if (mounted && address != null) {
      // Use deduplication to prevent duplicate API calls
      if (_shouldReloadData(address.code)) {
        _loadBillHistory();
      }
    }
  }

  bool _shouldReloadData(String? addressCode) {
    // Only reload if address is different OR cache expired
    if (_lastLoadedAddressId != addressCode) {
      _lastLoadedAddressId = addressCode;
      _lastLoadTime = DateTime.now();
      return true;
    }

    if (_lastLoadTime == null) {
      _lastLoadTime = DateTime.now();
      return true;
    }

    final timeSinceLoad = DateTime.now().difference(_lastLoadTime!);
    if (timeSinceLoad > _cacheDuration) {
      _lastLoadTime = DateTime.now();
      return true;
    }

    return false;
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // For testing, ensure we have a token
      await _ensureAuthToken();

      await _loadUserProfile();

      if (status != 'not_verified' && userId.isNotEmpty) {
        await _loadBillHistory();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading data: $e';
      });
    }
  }

  Future<void> _ensureAuthToken() async {
    try {
      final authService = AuthService();
      await authService.getAuthToken();
    } catch (e) {
      // Ignore errors here
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      // Get user info from auth untuk extract userCode (UUID)
      final authService = AuthService();
      final userInfo = await authService.getCurrentUser();

      if (userInfo != null) {
        userCode = userInfo['code']?.toString() ?? ''; // UUID dari login
        userId = userInfo['user_id']?.toString() ?? '';
      }

      // Also get profile data
      final result = await UserProfileService.instance.getCurrentUserProfile();

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        status = data.status ?? '';
        if (userId.isEmpty) {
          userId = data.userId ?? '';
        }

        // Load default address from AddressManager if needed, using userCode (UUID)
        if (status == 'verified' && userCode.isNotEmpty) {
          await AddressManager.instance.loadDefaultAddress(userCode);
        }
      } else {
        status = '';
        userId = '';
        userCode = '';
      }
    } catch (e) {
      status = '';
      userId = '';
      userCode = '';
    }
  }

  Future<void> _loadBillHistory() async {
    try {
      if (userId.isEmpty) {
        errorMessage = 'User ID not available';
        return;
      }

      // Use AddressManager as single source of truth
      final addressCode = AddressManager.instance.selectedAddressCode;

      if (addressCode == null) {
        errorMessage = 'No address selected';
        return;
      }

      // Load OrderDetails for BillCard
      final orderDetailsService = OrderDetailsService.instance;
      final orderDetailsResponse = await orderDetailsService.getOrderDetails(
        userId: userCode,
        userAddressId: addressCode,
      );

      if (orderDetailsResponse != null &&
          orderDetailsResponse.orders.isNotEmpty) {
        orderDetailsData = orderDetailsResponse;
        currentOrderDetail = orderDetailsResponse.orders.first;
        await _loadCurrentPlanName();
      } else {
        orderDetailsData = null;
        currentOrderDetail = null;
      }

      // Load BillHistory for Payment History section
      final billRequest = BillHistoryRequest(
        userCode: userCode,
        addressCode: addressCode,
      );

      final result = await BillService.instance.getBillHistory(billRequest);

      if (result['success'] == true && result['data'] != null) {
        billHistory = result['data'] as List<BillHistory>;
      } else {
        billHistory = [];
      }

      // Update state with address code
      setState(() {
        selectedAddressCode = addressCode;
      });
    } catch (e) {
      errorMessage = 'Error loading data: $e';
    }
  }

  Future<void> _loadCurrentPlanName() async {
    try {
      // Only use OrderDetails data for plan name
      if (currentOrderDetail != null) {
        final planName = currentOrderDetail!.productData.subsplanName.isNotEmpty
            ? currentOrderDetail!.productData.subsplanName
            : currentOrderDetail!.productData.productName.isNotEmpty
            ? currentOrderDetail!.productData.productName
            : currentOrderDetail!.serviceName;

        if (planName.isNotEmpty) {
          // Don't call setState here - will be called once in _loadData
          currentPlanName = planName;
        }
      }
    } catch (e) {
      // Keep default name if error occurs
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const AppBottomNavigation(currentRoute: '/pay'),
      );
    }

    // Show NotVerifiedWidget if user is not verified
    if (status == 'not_verified') {
      return const NotVerifiedWidget(currentRoute: '/pay');
    }

    // Normal Pay screen for verified users
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          CustomGradientHeader(
            title: 'Transaction',
            children: [
              // Show different states based on OrderDetails loading
              isLoading
                  ? Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF4CB04C),
                          ),
                        ),
                      ),
                    )
                  : currentOrderDetail != null
                  ? BillCard.fromOrderDetail(
                      orderDetail: currentOrderDetail!,
                      userId: userCode,
                      userAddressId: selectedAddressCode,
                    )
                  : const NoPlanWidget(),
            ],
          ),

          Container(
            width: double.infinity,
            color: const Color(0xFFF8F9FA),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: const Text(
              'Payment History',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                fontFamily: 'Open Sans',
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: errorMessage.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red.withOpacity(0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  errorMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                    fontFamily: 'Open Sans',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      isLoading = true;
                                      errorMessage = '';
                                    });
                                    _loadBillHistory();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : billHistory.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No payment history found',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontFamily: 'Open Sans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: billHistory.length,
                          separatorBuilder: (context, index) =>
                              Divider(color: Colors.grey.shade300),
                          itemBuilder: (context, index) {
                            final bill = billHistory[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BillDetailScreen(
                                      invoiceId: bill.invoiceId,
                                      invoiceNumber: bill.invoiceId,
                                      date: bill.formattedDate,
                                      amount: bill.formattedAmount,
                                      status: bill.displayStatus,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bill.formattedDate,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontFamily: 'Open Sans',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: bill.isPaid
                                                  ? const Color(0xFF82CBA3)
                                                  : const Color(0xFFCB8282),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              bill.displayStatus,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: bill.isPaid
                                                    ? const Color(0xFF1A451D)
                                                    : const Color(0xFF451A1A),
                                                fontFamily: 'Open Sans',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      bill.formattedAmount,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontFamily: 'Open Sans',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(currentRoute: '/pay'),
    );
  }
}
