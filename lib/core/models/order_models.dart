class OrderRequest {
  final String userId;
  final int productId;
  final int userAddressId;
  final String level;
  final String block;
  final String unitNumber;

  OrderRequest({
    required this.userId,
    required this.productId,
    required this.userAddressId,
    required this.level,
    required this.block,
    required this.unitNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_id': productId,
      'user_address_id': userAddressId,
      'level': level,
      'block': block,
      'unit_number': unitNumber,
    };
  }
}

class MidtransLink {
  final String token;
  final String redirectUrl;

  MidtransLink({required this.token, required this.redirectUrl});

  factory MidtransLink.fromJson(Map<String, dynamic> json) {
    return MidtransLink(
      token: json['token'] as String,
      redirectUrl: json['redirect_url'] as String,
    );
  }
}

class OrderResponse {
  final int productId;
  final String productName;
  final String productPrice;
  final String productDetail;
  final int subsplanId;
  final String subsplanName;
  final String paymentDeadline;
  final String status;
  final String invoiceStatus;
  final String orderStatus;
  final String code;
  final String amount;
  final MidtransLink midtransLink;
  final String midtransClient;
  final String merchantBaseUrl;
  final String midtransOrderId;
  final Map<String, dynamic>? data; // Added to store full order data

  OrderResponse({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productDetail,
    required this.subsplanId,
    required this.subsplanName,
    required this.paymentDeadline,
    required this.status,
    required this.invoiceStatus,
    required this.orderStatus,
    required this.code,
    required this.amount,
    required this.midtransLink,
    required this.midtransClient,
    required this.merchantBaseUrl,
    required this.midtransOrderId,
    this.data,
  });

  // Helper getters for invoice data
  String get invoiceNumber => data?['order']?['invoice']?['invoicenum'] ?? '';
  String get dueDate => data?['order']?['invoice']?['duedate'] ?? '';
  String get subtotal => data?['order']?['invoice']?['subtotal'] ?? '0';
  String get tax => data?['order']?['invoice']?['tax'] ?? '0';
  String get taxRate => data?['order']?['invoice']?['taxrate'] ?? '0';
  String get credit => data?['order']?['invoice']?['credit'] ?? '0';
  String get total => data?['order']?['invoice']?['total'] ?? '0';
  String get billingCycle =>
      data?['services']?[0]?['billingcycle'] ?? 'Monthly';

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      productId: json['productID'] as int,
      productName: json['productName'] as String,
      productPrice: json['productPrice'] as String,
      productDetail: json['productDetail'] as String,
      subsplanId: json['subsplanID'] as int,
      subsplanName: json['subsplanName'] as String,
      paymentDeadline: json['paymentDeadline'] as String,
      status: json['status'] as String,
      invoiceStatus: json['invoiceStatus'] as String,
      orderStatus: json['orderStatus'] as String,
      code: json['code'] as String,
      amount: json['amount'] as String,
      midtransLink: MidtransLink.fromJson(
        json['midtransLink'] as Map<String, dynamic>,
      ),
      midtransClient: json['midtransclient'] as String,
      merchantBaseUrl: json['merchantbaseurl'] as String,
      midtransOrderId: json['midtransorderid'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  String get formattedAmount {
    final amount = double.tryParse(this.amount) ?? 0;
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}
