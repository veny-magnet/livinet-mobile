import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/address_selector.dart';
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
  bool isLoading = true;
  List<BillHistory> billHistory = [];
  order_detail.OrderDetailsResponse? orderDetailsData;
  order_detail.OrderDetail? currentOrderDetail;
  String errorMessage = '';
  int? selectedAddressId;
  String currentPlanName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // For testing, ensure we have a token
    await _ensureAuthToken();

    await _loadUserProfile();
    if (status != 'not_verified') {
      await _loadBillHistory();
    }
  }

  Future<void> _ensureAuthToken() async {
    try {
      final authService = AuthService();
      final token = await authService.getAuthToken();

      if (token == null || token.isEmpty) {
        // For testing, set a dummy token
        // In production, this should redirect to login screen
        print('No auth token found - user should login first');
        // You might want to navigate to login screen here
      }
    } catch (e) {
      print('Error checking auth token: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final result = await UserProfileService.instance.getCurrentUserProfile();

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          status = data.status ?? '';
          userId = data.userId ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          status = '';
          userId = '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = '';
        userId = '';
        isLoading = false;
      });
    }
  }

  Future<void> _loadBillHistory() async {
    try {
      if (userId.isEmpty) {
        setState(() {
          errorMessage = 'User ID not available';
          isLoading = false;
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

          // Load OrderDetails for BillCard only
          print('PayScreen: Loading OrderDetails for BillCard...');
          final orderDetailsService = OrderDetailsService();
          final orderDetailsResponse = await orderDetailsService
              .getOrderDetails(
                userId: userId,
                userAddressId: selectedAddressId!,
              );

          if (orderDetailsResponse != null &&
              orderDetailsResponse.orders.isNotEmpty) {
            setState(() {
              orderDetailsData = orderDetailsResponse;
              currentOrderDetail = orderDetailsResponse.orders.first;
            });
            await _loadCurrentPlanName();
          } else {
            setState(() {
              orderDetailsData = null;
              currentOrderDetail = null;
            });
          }

          // Load BillHistory for Payment History section
          print('PayScreen: Loading BillHistory for Payment History...');
          final billRequest = BillHistoryRequest(
            userId: userId,
            userAddressId: selectedAddressId!,
          );

          final result = await BillService.instance.getBillHistory(billRequest);

          if (result['success'] == true && result['data'] != null) {
            setState(() {
              billHistory = result['data'] as List<BillHistory>;
              isLoading = false;
            });
          } else {
            setState(() {
              billHistory = [];
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = 'No address found';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load addresses';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
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
          setState(() {
            currentPlanName = planName;
          });
          print('PayScreen: Updated plan name from OrderDetails to: $planName');
        }
      }
    } catch (e) {
      print('PayScreen: Error loading current plan name: $e');
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
            title: 'Pay',
            children: [
              AddressSelector(
                userId: userId.isNotEmpty ? userId : '',
                defaultAddress: '',
                onTap: () {
                  // Handle address selection
                },
              ),
              const SizedBox(height: 10),
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
                      userId: userId,
                      userAddressId: selectedAddressId,
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
