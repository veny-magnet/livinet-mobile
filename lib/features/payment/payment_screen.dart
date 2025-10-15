import 'package:flutter/material.dart';
import '../../core/models/order_models.dart';
import '../../core/widgets/midtrans_payment_dialog.dart';
import '../home/home_screen.dart';

class PaymentScreen extends StatefulWidget {
  final OrderResponse orderResponse;

  const PaymentScreen({super.key, required this.orderResponse});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Helper getters untuk data real dari order response
  double get _subtotal => double.tryParse(widget.orderResponse.subtotal) ?? 0;
  double get _vat => double.tryParse(widget.orderResponse.tax) ?? 0;
  double get _credit => double.tryParse(widget.orderResponse.credit) ?? 0;
  double get _total => double.tryParse(widget.orderResponse.total) ?? 0;

  String get _formatSubtotal => 'Rp. ${_formatNumber(_subtotal)}';
  String get _formatVat => 'Rp. ${_formatNumber(_vat)}';
  String get _formatCredit => 'Rp. ${_formatNumber(_credit)}';
  String get _formatTotal => 'Rp. ${_formatNumber(_total)}';

  void _showMidtransPayment() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MidtransPaymentDialog(
        redirectUrl: widget.orderResponse.midtransLink.redirectUrl,
        orderResponse: widget.orderResponse,
        onPaymentComplete: (success) {
          // Close dialog first
          Navigator.of(context).pop();

          if (success) {
            // Use a slight delay to ensure dialog is fully closed
            // before navigating to prevent navigation conflicts
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              }
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Payment',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Open Sans',
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bill Number
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'No. Tagihan ${widget.orderResponse.midtransOrderId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Product Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.orderResponse.productName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.orderResponse.billingCycle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp. ${_formatNumber(_total)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  // Bill Summary Title
                  Text(
                    '${widget.orderResponse.productDetail} Bill Payment',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Open Sans',
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Bill Breakdown Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildBillRow(
                          'Product Subtotal',
                          'Rp. ${_formatNumber(_subtotal)}',
                        ),
                        const SizedBox(height: 16),
                        _buildBillRow(
                          '${widget.orderResponse.taxRate}% VAT',
                          'Rp. ${_formatNumber(_vat)}',
                        ),
                        const SizedBox(height: 16),
                        _buildBillRow(
                          'Credit',
                          'Rp. ${_formatNumber(_credit)}',
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        _buildBillRow(
                          'Total',
                          'Rp. ${_formatNumber(_total)}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Bottom Total and Pay Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(_total)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _showMidtransPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CB04C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    minimumSize: const Size(100, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Pay',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(
    String label,
    String amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: Colors.black,
            fontFamily: 'Open Sans',
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isDiscount ? Colors.green : Colors.black,
            fontFamily: 'Open Sans',
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
