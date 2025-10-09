import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/address_selector.dart';
import '../../core/widgets/bill_card.dart';
import '../../core/widgets/custom_gradient_header.dart';
import '../../core/widgets/not_verified_widget.dart';
import '../../core/services/user_profile_service.dart';
import '../payment/payment_screen.dart';

class PayScreen extends StatefulWidget {
  const PayScreen({super.key});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  String status = '';
  bool isLoading = true;

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
          isLoading = false;
        });
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
                address: 'Apartemen Mediterania Lt. 31 Unit 32AN',
                onTap: () {
                  // Handle address selection
                },
              ),
              const SizedBox(height: 10),
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
                    itemCount: 5,
                    separatorBuilder: (context, index) =>
                        Divider(color: Colors.grey.shade300),
                    itemBuilder: (context, index) {
                      final isPaid = index % 2 == 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '28 Feb 2025',
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
                                      isPaid ? 'PAID' : 'UNPAID',
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
                            const Text(
                              'Rp 225,000',
                              style: TextStyle(
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
}
