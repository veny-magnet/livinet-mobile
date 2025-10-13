import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/models/order_summary.dart';

class PaymentScreen extends StatefulWidget {
  final OrderSummary orderSummary;

  const PaymentScreen({super.key, required this.orderSummary});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _usePoints = false;
  final int _availablePoints = 0;
  final double _pointDiscount = 0;

  late double _subtotal;
  late double _vat;
  late double _credit;

  double get _finalTotal =>
      _subtotal + _vat - _credit - (_usePoints ? _pointDiscount : 0);

  @override
  void initState() {
    super.initState();
    _subtotal = widget.orderSummary.subtotal;
    _vat = widget.orderSummary.tax;
    _credit = widget.orderSummary.credit;
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.orderSummary;
    final hasMidtransUrl = summary.midtransRedirectUrl.isNotEmpty;

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      summary.billNumber.isNotEmpty
                          ? 'No. Tagihan ${summary.billNumber}'
                          : 'No. Tagihan -',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.productName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                            if (summary.productDetail.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                summary.productDetail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                            ],
                            if (summary.periodLabel.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                summary.periodLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        'Rp ${_formatNumber(summary.amount)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Use Voucher',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Exchange Your ${_formatNumber(_availablePoints)} points',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: _usePoints
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF4CB04C),
                                      Color(0xFFF8D86E),
                                    ],
                                  )
                                : null,
                            color: _usePoints ? null : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Switch(
                            value: _usePoints,
                            onChanged: (value) {
                              setState(() {
                                _usePoints = value;
                              });
                            },
                            activeColor: Colors.white,
                            inactiveThumbColor: Colors.white,
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            trackOutlineColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            splashRadius: 0,
                            thumbIcon: null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Bill Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Open Sans',
                    ),
                  ),

                  const SizedBox(height: 16),
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
                        _buildBillRow('VAT', 'Rp. ${_formatNumber(_vat)}'),
                        const SizedBox(height: 16),
                        _buildBillRow(
                          'Credit',
                          'Rp. ${_formatNumber(_credit)}',
                        ),
                        const SizedBox(height: 16),
                        _buildBillRow(
                          'Point Discount',
                          _usePoints && _pointDiscount > 0
                              ? '-Rp. ${_formatNumber(_pointDiscount)}'
                              : 'Rp. 0',
                          isDiscount: _usePoints && _pointDiscount > 0,
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        _buildBillRow(
                          'Total',
                          'Rp. ${_formatNumber(_finalTotal)}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

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
                      'Rp ${_formatNumber(_finalTotal)}',
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
                  onPressed: hasMidtransUrl ? _showMidtransDialog : null,
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

  String _formatNumber(num number) {
    final intValue = number.round();
    return intValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Future<void> _showMidtransDialog() async {
    final url = widget.orderSummary.midtransRedirectUrl;
    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link Midtrans tidak valid.')),
        );
      }
      return;
    }

    final loadingNotifier = ValueNotifier<bool>(true);
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => loadingNotifier.value = false,
          onWebResourceError: (_) => loadingNotifier.value = false,
        ),
      )
      ..loadRequest(uri);

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            height: MediaQuery.of(dialogContext).size.height * 0.7,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  WebViewWidget(controller: controller),
                  ValueListenableBuilder<bool>(
                    valueListenable: loadingNotifier,
                    builder: (_, isLoading, __) {
                      if (!isLoading) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        color: Colors.white.withOpacity(0.6),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SafeArea(
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
