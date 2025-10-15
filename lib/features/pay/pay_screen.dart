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
import '../../core/services/subscription_service.dart';
import '../../core/services/address_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/bill_models.dart';

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
  String errorMessage = '';
  int? selectedAddressId;
  String currentPlanName = ''; // Will be loaded from API

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

          // Get bill history
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

            // Load plan name after getting bill history
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
                  isLoading = false;
                });

                // Load plan name after getting subscription bills
                await _loadCurrentPlanName();
              } else {
                setState(() {
                  errorMessage =
                      result['message'] ??
                      'Failed to load bill history and subscriptions';
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
        errorMessage = 'Error loading bill history: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentPlanName() async {
    try {
      if (userId.isNotEmpty && selectedAddressId != null) {
        print('PayScreen: Loading subscription data for userId: $userId');

        // Get subscription data to find the current plan name using subsplanName
        final subscriptionResult = await SubscriptionService.instance
            .getUserSubscriptions(userId);

        print('PayScreen: Subscription API response: $subscriptionResult');

        if (subscriptionResult['success'] == true &&
            subscriptionResult['data'] != null) {
          final subscriptionData =
              subscriptionResult['data'] as Map<String, dynamic>;

          print('PayScreen: Subscription data: $subscriptionData');

          final subscriptions =
              subscriptionData['subscriptions'] as List<dynamic>? ?? [];

          print('PayScreen: Found ${subscriptions.length} subscriptions');

          if (subscriptions.isNotEmpty) {
            final currentSubscription = subscriptions.first;
            print(
              'PayScreen: Current subscription details: $currentSubscription',
            );

            // Priority: use subsplanName from subscription response
            final planName =
                currentSubscription['subsplanName']?.toString() ??
                currentSubscription['productDescription']?.toString() ??
                currentSubscription['plan_name']?.toString() ??
                currentSubscription['name']?.toString();

            print('PayScreen: Extracted plan name: $planName');

            if (planName != null && planName.isNotEmpty) {
              setState(() {
                currentPlanName = planName;
              });
              print(
                'PayScreen: Updated plan name from subscription to: $planName',
              );
              return;
            } else {
              print('PayScreen: No valid plan name found in subscription data');
            }
          } else {
            print('PayScreen: No subscriptions found in response');
          }
        } else {
          print('PayScreen: Subscription API failed or returned no data');
          print('PayScreen: Success: ${subscriptionResult['success']}');
          print('PayScreen: Message: ${subscriptionResult['message']}');
        }
      } else {
        print(
          'PayScreen: Cannot load plan name - userId: $userId, selectedAddressId: $selectedAddressId',
        );
      }
    } catch (e) {
      print('PayScreen: Error loading current plan name: $e');
      // Keep default name if error occurs
    }
  }

  void _handlePayPressed() {
    // Get unpaid bill for payment
    final unpaidBill = billHistory.where((bill) => !bill.isPaid).firstOrNull;

    if (unpaidBill != null) {
      // For now, show message that payment feature is coming soon
      // In real implementation, you would navigate to payment gateway
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment for bill ${unpaidBill.invoiceId} - ${unpaidBill.formattedAmount}',
          ),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: 'Open Payment',
            onPressed: () {
              // TODO: Navigate to payment gateway or PaymentScreen
              print('Open payment for invoice: ${unpaidBill.invoiceId}');
              print('Midtrans Order ID: ${unpaidBill.midtransOrderId}');
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No unpaid bills found'),
          backgroundColor: Colors.orange,
        ),
      );
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
                      onPayPressed: billHistory.any((bill) => !bill.isPaid)
                          ? _handlePayPressed
                          : null,
                    ),
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
                                      invoiceNumber: bill
                                          .invoiceId, // Using invoiceId for now
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
