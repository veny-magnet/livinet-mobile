import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/address_selector.dart';
import '../../core/widgets/bill_card.dart';
import '../../core/widgets/custom_gradient_header.dart';
import '../../core/widgets/not_verified_widget.dart';
import '../../core/services/user_profile_service.dart';
import '../../core/services/order_service.dart';
import '../../core/services/bill_service.dart';
import '../../core/models/order_summary.dart';
import '../payment/payment_screen.dart';

class PayScreen extends StatefulWidget {
  const PayScreen({super.key});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  String status = '';
  bool isLoading = true;
  bool isPlacingOrder = false;
  List<dynamic> billHistory = [];
  Map<String, dynamic>? currentBill;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      const String defaultUserId = 'CR006000';
      final result = await UserProfileService.instance.getUserProfile(
        defaultUserId,
      );

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        setState(() {
          status = data.status ?? '';
        });

        // Load bills only if user is verified
        if (status == 'verified') {
          await _loadBillData(defaultUserId);
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          status = '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = '';
        isLoading = false;
      });
    }
  }

  Future<void> _loadBillData(String userId) async {
    try {
      final result = await BillService.instance.getBillHistory(userId: userId);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final bills = data['bills'] as List<dynamic>? ?? [];

        setState(() {
          billHistory = bills;
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
          billHistory = [];
          currentBill = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        billHistory = [];
        currentBill = null;
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
                userId: 'CR006000',
                defaultAddress: 'Apartemen Mediterania Lt. 31 Unit 32AN',
                onTap: () {
                  // Handle address selection
                },
              ),
              const SizedBox(height: 10),
              BillCard(
                planName: currentBill?['product_name'] ?? 'No Active Plan',
                billLabel: 'Your Bill',
                amount: currentBill != null
                    ? 'Rp ${(currentBill!['amount'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
                    : 'Rp 0',
                status: currentBill?['status'] ?? 'none',
                isProcessing: isPlacingOrder,
                onPayPressed: currentBill != null && !isPlacingOrder
                    ? _handlePay
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
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: billHistory.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: Colors.grey.shade300),
                    itemBuilder: (context, index) {
                      final bill = billHistory[index];
                      final isPaid = bill['status'] == 'paid';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(
                                      bill['created_at'] ??
                                          bill['payment_deadline'] ??
                                          '',
                                    ),
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
                                      color: isPaid
                                          ? const Color(0xFF82CBA3)
                                          : const Color(0xFFCB8282),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      (bill['status'] ?? 'UNKNOWN')
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isPaid
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
                              'Rp ${(bill['amount'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
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

  Future<void> _handlePay() async {
    if (isPlacingOrder) {
      return;
    }
    setState(() {
      isPlacingOrder = true;
    });

    try {
      const defaultUserId = 'CR006000';
      const defaultProductId = 24;
      const defaultAddressId = 1;
      const defaultLevel = '2';
      const defaultBlock = 'A';
      const defaultUnitNumber = '201';

      final result = await OrderService.instance.createOrder(
        userId: defaultUserId,
        productId: defaultProductId,
        userAddressId: defaultAddressId,
        level: defaultLevel,
        block: defaultBlock,
        unitNumber: defaultUnitNumber,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true && result['data'] is OrderSummary) {
        final summary = result['data'] as OrderSummary;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(orderSummary: summary),
          ),
        );
      } else {
        final message = result['message']?.toString() ?? 'Gagal membuat order.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isPlacingOrder = false;
        });
      }
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }
}
