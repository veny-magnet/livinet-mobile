import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/order_models.dart';
import '../../core/models/order_detail_models.dart' as order_detail;

// Wrapper class to handle both OrderResponse and OrderDetail
class PaymentData {
  final int? orderId;
  final String? invoiceStatus;
  final String subtotal;
  final String tax;
  final String taxRate;
  final String credit;
  final String total;
  final String productName;
  final String productDetail;
  final String billingCycle;
  final String midtransOrderId;
  final String midtransToken;
  final String midtransClientKey;
  final String midtransRedirectUrl;
  final String? setupFee;
  final String? serviceCost;
  final String? setupFeeDescription;
  final String? recurringServiceDescription;

  PaymentData({
    this.orderId,
    this.invoiceStatus,
    required this.subtotal,
    required this.tax,
    required this.taxRate,
    required this.credit,
    required this.total,
    required this.productName,
    required this.productDetail,
    required this.billingCycle,
    required this.midtransOrderId,
    required this.midtransToken,
    required this.midtransClientKey,
    required this.midtransRedirectUrl,
    this.setupFee,
    this.serviceCost,
    this.setupFeeDescription,
    this.recurringServiceDescription,
  });

  // Create from OrderResponse
  factory PaymentData.fromOrderResponse(OrderResponse order) {
    return PaymentData(
      subtotal: order.subtotal,
      tax: order.tax,
      taxRate: order.taxRate,
      credit: order.credit,
      total: order.total,
      productName: order.productName,
      productDetail: order.productDetail,
      billingCycle: order.billingCycle,
      midtransOrderId: order.midtransOrderId,
      midtransToken: order.midtransLink.token,
      midtransClientKey: order.midtransClient,
      midtransRedirectUrl: order.midtransLink.redirectUrl,
    );
  }

  // Create from OrderDetail
  factory PaymentData.fromOrderDetail(order_detail.OrderDetail order) {
    return PaymentData(
      orderId: order.id,
      invoiceStatus: order.invoiceStatus,
      subtotal: order.subtotal,
      tax: order.tax,
      taxRate: order.taxRate,
      credit: order.credit,
      total: order.total,
      productName: order.productName,
      productDetail: order.serviceGroup,
      billingCycle: order.billingCycle,
      midtransOrderId: order.midtransOrderId,
      midtransToken: order.midtransData.midtransToken,
      midtransClientKey: order.midtransData.midtransClientKey,
      midtransRedirectUrl: order.midtransData.midtransRedirectUrl,
      setupFee: order.invoiceDetails.setupFee?.amount,
      serviceCost: order.invoiceDetails.recurringService?.amount,
      setupFeeDescription: order.invoiceDetails.setupFee?.description,
      recurringServiceDescription:
          order.invoiceDetails.recurringService?.description,
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final PaymentData orderData;
  final OrderResponse? orderResponse;

  const PaymentScreen({super.key, required this.orderData, this.orderResponse});

  // Constructor for OrderResponse (backward compatibility)
  PaymentScreen.fromOrderResponse({
    super.key,
    required OrderResponse orderResponse,
  }) : orderData = PaymentData.fromOrderResponse(orderResponse),
       orderResponse = orderResponse;

  // Constructor for OrderDetail
  PaymentScreen.fromOrderDetail({
    super.key,
    required order_detail.OrderDetail orderDetail,
  }) : orderData = PaymentData.fromOrderDetail(orderDetail),
       orderResponse = null;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Helper getters untuk data dari PaymentData
  double get _subtotal => double.tryParse(widget.orderData.subtotal) ?? 0;
  double get _vat => double.tryParse(widget.orderData.tax) ?? 0;
  double get _credit => double.tryParse(widget.orderData.credit) ?? 0;
  double get _total => double.tryParse(widget.orderData.total) ?? 0;

  @override
  void initState() {
    super.initState();
  }

  void _showMidtransPayment() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MidtransSnapDialog(
        snapToken: widget.orderData.midtransToken,
        clientKey: widget.orderData.midtransClientKey,
        isProduction: false, // Set true untuk production
        onPaymentFinished: _handlePaymentResult,
      ),
    );
  }

  void _handlePaymentResult(Map<String, dynamic> result) {
    final status = result['status'] ?? 'unknown';

    // Add small delay to ensure Midtrans dialog is fully closed
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (status == 'success') {
        // Payment successful - show success dialog
        _showPaymentSuccessDialog();
      } else if (status == 'pending') {
        // Payment pending - show pending dialog
        _showPaymentPendingDialog();
      } else if (status == 'error') {
        // Payment error - show error dialog
        _showPaymentErrorDialog(
          result['message'] ?? 'Payment failed. Please try again.',
        );
      } else if (status == 'closed') {
        // User cancelled - do nothing, stay on payment screen
        return;
      }
    });
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CB04C).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 40,
                      color: Color(0xFF4CB04C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Open Sans',
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your payment has been submitted successfully.',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Open Sans',
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        // Add delay to ensure dialog is fully closed before navigation
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted) {
                            context.go('/home', extra: {'shouldRefresh': true});
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CB04C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  void _showPaymentPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pending_outlined,
                      size: 40,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Pending',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Open Sans',
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Payment pending. Please complete your payment.',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Open Sans',
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        // Add delay to ensure dialog is fully closed before navigation
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted) {
                            context.go('/home', extra: {'shouldRefresh': true});
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  void _showPaymentErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Failed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Open Sans',
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Open Sans',
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        // Add delay to ensure dialog is fully closed before navigation
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted) {
                            context.go('/home', extra: {'shouldRefresh': true});
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 40,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 20,
              ),
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
                          'No. Tagihan ${widget.orderData.midtransOrderId}',
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
                                  widget.orderData.productName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontFamily: 'Open Sans',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.orderData.billingCycle,
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
                        '${widget.orderData.productDetail} Bill Payment',
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
                            // Cost Breakdown Section (if available)
                            if (widget.orderData.setupFee != null ||
                                widget.orderData.serviceCost != null) ...[
                              // Setup Fee
                              if (widget.orderData.setupFee != null)
                                _buildBillRow(
                                  widget.orderData.setupFeeDescription ??
                                      'Setup Fee',
                                  'Rp. ${_formatNumber(double.tryParse(widget.orderData.setupFee!) ?? 0)}',
                                ),

                              // Service Cost
                              if (widget.orderData.serviceCost != null) ...[
                                if (widget.orderData.setupFee != null)
                                  const SizedBox(height: 16),
                                _buildBillRow(
                                  widget
                                          .orderData
                                          .recurringServiceDescription ??
                                      'Service Cost',
                                  'Rp. ${_formatNumber(double.tryParse(widget.orderData.serviceCost!) ?? 0)}',
                                ),
                              ],

                              const SizedBox(height: 16),
                              _buildBillRow(
                                'Subtotal',
                                'Rp. ${_formatNumber(_subtotal)}',
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              _buildBillRow(
                                'Product Subtotal',
                                'Rp. ${_formatNumber(_subtotal)}',
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Tax
                            _buildBillRow(
                              '${widget.orderData.taxRate}% VAT',
                              'Rp. ${_formatNumber(_vat)}',
                            ),

                            // Credit (if any)
                            if (_credit > 0) ...[
                              const SizedBox(height: 16),
                              _buildBillRow(
                                'Credit',
                                '- Rp. ${_formatNumber(_credit)}',
                                isDiscount: true,
                              ),
                            ],

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
                    // Hanya tampilkan tombol Pay jika status bukan "paid"
                    if (widget.orderData.invoiceStatus?.toLowerCase() != 'paid')
                      ElevatedButton(
                        onPressed: _showMidtransPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CB04C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
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
        ),
      ],
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
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: Colors.black,
              fontFamily: 'Open Sans',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
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

class MidtransSnapDialog extends StatefulWidget {
  final String snapToken;
  final String clientKey;
  final Function(Map<String, dynamic>) onPaymentFinished;
  final bool isProduction;

  const MidtransSnapDialog({
    super.key,
    required this.snapToken,
    required this.clientKey,
    required this.onPaymentFinished,
    this.isProduction = false,
  });

  @override
  State<MidtransSnapDialog> createState() => _MidtransSnapDialogState();
}

class _MidtransSnapDialogState extends State<MidtransSnapDialog> {
  bool _isLoading = true;
  bool _isPaymentProcessed = false; // Flag untuk mencegah multiple callbacks

  String get _snapUrl {
    return widget.isProduction
        ? 'https://app.midtrans.com/snap/snap.js'
        : 'https://app.sandbox.midtrans.com/snap/snap.js';
  }

  void _handlePaymentFinished(Map<String, dynamic> result) {
    // Cegah multiple callbacks
    if (_isPaymentProcessed) {
      return;
    }

    _isPaymentProcessed = true;

    // Close dialog
    if (mounted) {
      Navigator.of(context).pop();

      // Call callback directly without delay
      widget.onPaymentFinished(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Ketika user menekan back button
        if (!_isPaymentProcessed) {
          _handlePaymentFinished({'status': 'closed'});
        }
        return false; // Prevent default back action
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // WebView Content
              Flexible(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: InAppWebView(
                        initialData: InAppWebViewInitialData(
                          data: _generateHtmlContent(),
                          baseUrl: WebUri(_snapUrl.split('/snap.js')[0]),
                        ),
                        initialSettings: InAppWebViewSettings(
                          javaScriptEnabled: true,
                          domStorageEnabled: true,
                          allowFileAccess: true,
                          allowContentAccess: true,
                          useHybridComposition: true,
                          transparentBackground: true,
                          supportZoom: false,
                          builtInZoomControls: false,
                          disableHorizontalScroll: false,
                          disableVerticalScroll: false,
                        ),
                        onWebViewCreated: (controller) {
                          // Add JavaScript handler to receive payment result
                          controller.addJavaScriptHandler(
                            handlerName: 'PaymentFinish',
                            callback: (args) {
                              if (args.isNotEmpty && !_isPaymentProcessed) {
                                final result = args[0] as Map<String, dynamic>;
                                _handlePaymentFinished(result);
                              }
                            },
                          );
                        },
                        onLoadStart: (controller, url) {
                          print('WebView Loading: $url');
                        },
                        shouldOverrideUrlLoading:
                            (controller, navigationAction) async {
                              final url = navigationAction.request.url
                                  .toString();
                              print('URL Navigation: $url');

                              // Check if URL is a redirect URL (contains status parameter or is redirect endpoint)
                              if (url.contains('status=') ||
                                  url.contains('redirect') ||
                                  url.contains('/payment-result') ||
                                  url.contains('/api/payment')) {
                                print(' Redirect URL detected: $url');

                                try {
                                  // Extract status from URL
                                  final uri = Uri.parse(url);
                                  final status =
                                      uri.queryParameters['status'] ??
                                      uri.queryParameters['transaction_status'];

                                  if (status != null) {
                                    print(
                                      'Payment status from redirect: $status',
                                    );

                                    // Map transaction status to our status
                                    String mappedStatus = status.toLowerCase();
                                    if (mappedStatus.contains('settlement') ||
                                        mappedStatus == 'success') {
                                      _handlePaymentFinished({
                                        'status': 'success',
                                      });
                                    } else if (mappedStatus.contains(
                                      'pending',
                                    )) {
                                      _handlePaymentFinished({
                                        'status': 'pending',
                                      });
                                    } else {
                                      _handlePaymentFinished({
                                        'status': 'error',
                                        'message': 'Payment failed',
                                      });
                                    }
                                    return NavigationActionPolicy
                                        .CANCEL; // Don't load the redirect URL
                                  }
                                } catch (e) {
                                  print('Error parsing redirect URL: $e');
                                }
                              }

                              // Allow other URLs to load normally
                              return NavigationActionPolicy.ALLOW;
                            },
                        onLoadStop: (controller, url) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                        onConsoleMessage: (controller, consoleMessage) {
                          print(' WebView Console: ${consoleMessage.message}');
                        },
                        onLoadError: (controller, url, code, message) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                          print('❌ WebView Error: $message (Code: $code)');
                        },
                      ),
                    ),
                    if (_isLoading)
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4CB04C),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading payment...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'Open Sans',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _generateHtmlContent() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <script type="text/javascript" src="$_snapUrl" data-client-key="${widget.clientKey}"></script>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    html, body {
      width: 100%;
      height: 100%;
      overflow: hidden;
    }
    
    body {
      font-family: 'Open Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background-color: #ffffff;
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 0;
    }
    
    #snap-container {
      width: 100%;
      height: 100%;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    
    .loading {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 16px;
    }
    
    .spinner {
      width: 40px;
      height: 40px;
      border: 4px solid #f3f3f3;
      border-top: 4px solid #4CB04C;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
    
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    
    .loading-text {
      color: #666;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div id="snap-container">
    <div class="loading">
      <div class="spinner"></div>
      <div class="loading-text">Initializing payment...</div>
    </div>
  </div>
  
  <script type="text/javascript">
    console.log('Starting Midtrans Snap initialization...');
    
    var paymentProcessed = false; // Flag to prevent multiple callbacks
    
    function sendPaymentResult(result) {
      if (paymentProcessed) {
        console.log('Payment already processed, skipping...');
        return;
      }
      paymentProcessed = true;
      console.log('Sending payment result:', JSON.stringify(result));
      
      if (window.flutter_inappwebview) {
        try {
          window.flutter_inappwebview.callHandler('PaymentFinish', result);
          console.log('Payment result sent to Flutter');
        } catch (e) {
          console.error('Error calling flutter handler:', e);
        }
      } else {
        console.warn('flutter_inappwebview not available');
      }
    }
    
    function initializePayment() {
      console.log('initializePayment called');
      
      if (typeof window.snap === 'undefined') {
        console.error('Snap.js not loaded, retrying...');
        setTimeout(initializePayment, 500);
        return;
      }
      
      console.log('Snap.js ready, calling snap.pay...');
      
      try {
        window.snap.pay('${widget.snapToken}', {
          onSuccess: function(result) {
            console.log('Payment SUCCESS:', JSON.stringify(result));
            sendPaymentResult({
              status: 'success',
              result: result,
              transaction_status: result.transaction_status
            });
          },
          onPending: function(result) {
            console.log('Payment PENDING:', JSON.stringify(result));
            sendPaymentResult({
              status: 'pending',
              result: result,
              transaction_status: result.transaction_status
            });
          },
          onError: function(result) {
            console.log('Payment ERROR:', JSON.stringify(result));
            sendPaymentResult({
              status: 'error',
              result: result,
              message: result.status_message || 'Payment failed'
            });
          },
          onClose: function() {
            console.log('Payment popup CLOSED by user');
            if (!paymentProcessed) {
              sendPaymentResult({
                status: 'closed'
              });
            }
          }
        });
        
        console.log('snap.pay called successfully');
      } catch (error) {
        console.error('Error calling snap.pay:', error);
        sendPaymentResult({
          status: 'error',
          message: error.toString()
        });
      }
    }

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', function() {
        console.log('DOM Content Loaded');
        setTimeout(initializePayment, 1000);
      });
    } else {
      console.log('DOM already loaded');
      setTimeout(initializePayment, 1000);
    }
  </script>
</body>
</html>
''';
  }
}
