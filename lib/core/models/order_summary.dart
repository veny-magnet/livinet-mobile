class OrderSummary {
  final int productId;
  final String productName;
  final String productDetail;
  final double amount;
  final double subtotal;
  final double tax;
  final double credit;
  final String paymentDeadline;
  final String status;
  final String invoiceStatus;
  final String orderStatus;
  final String code;
  final String billNumber;
  final String periodLabel;
  final String midtransToken;
  final String midtransRedirectUrl;
  final String midtransClient;
  final String merchantBaseUrl;
  final String midtransOrderId;
  final String invoiceId;
  final Map<String, dynamic> raw;

  OrderSummary({
    required this.productId,
    required this.productName,
    required this.productDetail,
    required this.amount,
    required this.subtotal,
    required this.tax,
    required this.credit,
    required this.paymentDeadline,
    required this.status,
    required this.invoiceStatus,
    required this.orderStatus,
    required this.code,
    required this.billNumber,
    required this.periodLabel,
    required this.midtransToken,
    required this.midtransRedirectUrl,
    required this.midtransClient,
    required this.merchantBaseUrl,
    required this.midtransOrderId,
    required this.invoiceId,
    required this.raw,
  });

  factory OrderSummary.fromApi(Map<String, dynamic> json) {
    final productId = json['productID'] ?? json['product_id'] ?? 0;
    final productName = json['productName']?.toString() ?? '';
    final productDetail = json['productDetail']?.toString() ?? '';
    final amount = _parseToDouble(json['amount']);
    final paymentDeadline = json['paymentDeadline']?.toString() ?? '';
    final status = json['status']?.toString() ?? '';
    final invoiceStatus = json['invoiceStatus']?.toString() ?? '';
    final orderStatus = json['orderStatus']?.toString() ?? '';
    final code = json['code']?.toString() ?? '';
    final subsplanName = json['subsplanName']?.toString() ?? '';

    final order = json['order'] as Map<String, dynamic>? ?? {};
    final invoice = order['invoice'] as Map<String, dynamic>? ?? {};
    final services = json['services'] as List<dynamic>? ?? [];
    final midtransLink = json['midtransLink'] as Map<String, dynamic>? ?? {};

    final subtotal = _parseToDouble(invoice['subtotal']);
    final tax = _parseToDouble(invoice['tax']);
    final credit = _parseToDouble(invoice['credit']);
    final billNumber = invoice['invoicenum']?.toString() ?? '';
    final invoiceId = invoice['id']?.toString() ?? '';

    final periodLabel = _buildPeriodLabel(
      invoice['date']?.toString(),
      invoice['duedate']?.toString(),
    );

    final mergedProductDetail = productDetail.isNotEmpty
        ? productDetail
        : (services.isNotEmpty
              ? services.first['groupname']?.toString() ??
                    services.first['translated_groupname']?.toString() ??
                    ''
              : '');

    return OrderSummary(
      productId: productId is int
          ? productId
          : int.tryParse(productId.toString()) ?? 0,
      productName: productName.isNotEmpty ? productName : subsplanName,
      productDetail: mergedProductDetail,
      amount: amount,
      subtotal: subtotal,
      tax: tax,
      credit: credit,
      paymentDeadline: paymentDeadline,
      status: status,
      invoiceStatus: invoiceStatus,
      orderStatus: orderStatus,
      code: code,
      billNumber: billNumber,
      periodLabel: periodLabel,
      midtransToken: midtransLink['token']?.toString() ?? '',
      midtransRedirectUrl: midtransLink['redirect_url']?.toString() ?? '',
      midtransClient: json['midtransclient']?.toString() ?? '',
      merchantBaseUrl: json['merchantbaseurl']?.toString() ?? '',
      midtransOrderId: json['midtransorderid']?.toString() ?? '',
      invoiceId: invoiceId,
      raw: json,
    );
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    final parsed = double.tryParse(value.toString());
    return parsed ?? 0;
  }

  static String _buildPeriodLabel(String? start, String? end) {
    if ((start == null || start.isEmpty) && (end == null || end.isEmpty)) {
      return '';
    }
    if (start != null && start.isNotEmpty && end != null && end.isNotEmpty) {
      return '($start to $end)';
    }
    return start?.isNotEmpty == true ? start! : end ?? '';
  }
}
