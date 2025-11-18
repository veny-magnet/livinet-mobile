// Order Details Models
class OrderDetailsRequest {
  final String userId;
  final String? userAddressId;

  OrderDetailsRequest({required this.userId, this.userAddressId});

  Map<String, String> toQueryParams() {
    final params = <String, String>{'code': userId};
    if (userAddressId != null) {
      params['address_code'] = userAddressId!;
    }
    return params;
  }
}

class SetupFee {
  final String amount;
  final String description;
  final bool isSetupFeeIncluded;

  SetupFee({
    required this.amount,
    required this.description,
    required this.isSetupFeeIncluded,
  });

  factory SetupFee.fromJson(Map<String, dynamic> json) {
    return SetupFee(
      amount: json['amount']?.toString() ?? '0',
      description: json['description']?.toString() ?? '',
      isSetupFeeIncluded: json['is_setup_fee_included'] == true,
    );
  }
}

class RecurringService {
  final String amount;
  final String description;

  RecurringService({required this.amount, required this.description});

  factory RecurringService.fromJson(Map<String, dynamic> json) {
    return RecurringService(
      amount: json['amount']?.toString() ?? '0',
      description: json['description']?.toString() ?? '',
    );
  }
}

class CostBreakdown {
  final String setupFee;
  final String serviceCost;
  final String subtotalBeforeTax;
  final String taxAmount;
  final String totalAmount;

  CostBreakdown({
    required this.setupFee,
    required this.serviceCost,
    required this.subtotalBeforeTax,
    required this.taxAmount,
    required this.totalAmount,
  });

  factory CostBreakdown.fromJson(Map<String, dynamic> json) {
    return CostBreakdown(
      setupFee: json['setup_fee']?.toString() ?? '0',
      serviceCost: json['service_cost']?.toString() ?? '0',
      subtotalBeforeTax: json['subtotal_before_tax']?.toString() ?? '0',
      taxAmount: json['tax_amount']?.toString() ?? '0',
      totalAmount: json['total_amount']?.toString() ?? '0',
    );
  }
}

class InvoiceDetails {
  final String subtotal;
  final String tax;
  final String taxRate;
  final String tax2;
  final String taxRate2;
  final String total;
  final String balance;
  final String amountPaid;
  final String credit;
  final SetupFee? setupFee;
  final RecurringService? recurringService;
  final CostBreakdown? costBreakdown;

  InvoiceDetails({
    required this.subtotal,
    required this.tax,
    required this.taxRate,
    required this.tax2,
    required this.taxRate2,
    required this.total,
    required this.balance,
    required this.amountPaid,
    required this.credit,
    this.setupFee,
    this.recurringService,
    this.costBreakdown,
  });

  factory InvoiceDetails.fromJson(Map<String, dynamic> json) {
    return InvoiceDetails(
      subtotal: json['subtotal']?.toString() ?? '0',
      tax: json['tax']?.toString() ?? '0',
      taxRate: json['tax_rate']?.toString() ?? '0',
      tax2: json['tax2']?.toString() ?? '0',
      taxRate2: json['tax_rate2']?.toString() ?? '0',
      total: json['total']?.toString() ?? '0',
      balance: json['balance']?.toString() ?? '0',
      amountPaid: json['amount_paid']?.toString() ?? '0',
      credit: json['credit']?.toString() ?? '0',
      setupFee: json['setup_fee'] != null
          ? SetupFee.fromJson(json['setup_fee'])
          : null,
      recurringService: json['recurring_service'] != null
          ? RecurringService.fromJson(json['recurring_service'])
          : null,
      costBreakdown: json['cost_breakdown'] != null
          ? CostBreakdown.fromJson(json['cost_breakdown'])
          : null,
    );
  }
}

class MidtransData {
  final String midtransOrderId;
  final String midtransToken;
  final String midtransRedirectUrl;
  final String midtransClientKey;
  final String midtransMerchantBaseUrl;
  final String paymentMethod;
  final String paymentGatewayName;

  MidtransData({
    required this.midtransOrderId,
    required this.midtransToken,
    required this.midtransRedirectUrl,
    required this.midtransClientKey,
    required this.midtransMerchantBaseUrl,
    required this.paymentMethod,
    required this.paymentGatewayName,
  });

  factory MidtransData.fromJson(Map<String, dynamic> json) {
    return MidtransData(
      midtransOrderId: json['midtrans_order_id']?.toString() ?? '',
      midtransToken: json['midtrans_token']?.toString() ?? '',
      midtransRedirectUrl: json['midtrans_redirect_url']?.toString() ?? '',
      midtransClientKey: json['midtrans_client_key']?.toString() ?? '',
      midtransMerchantBaseUrl:
          json['midtrans_merchant_base_url']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentGatewayName: json['payment_gateway_name']?.toString() ?? '',
    );
  }
}

class ProductData {
  final int productId;
  final String productName;
  final String productPrice;
  final String productDetail;
  final int subsplanId;
  final String subsplanName;

  ProductData({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productDetail,
    required this.subsplanId,
    required this.subsplanName,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      productId: json['product_id'] ?? 0,
      productName: json['product_name']?.toString() ?? '',
      productPrice: json['product_price']?.toString() ?? '0',
      productDetail: json['product_detail']?.toString() ?? '',
      subsplanId: json['subsplan_id'] ?? 0,
      subsplanName: json['subsplan_name']?.toString() ?? '',
    );
  }
}

class StatusData {
  final String orderStatus;
  final String? paymentDeadline;
  final bool isPaid;

  StatusData({
    required this.orderStatus,
    this.paymentDeadline,
    required this.isPaid,
  });

  factory StatusData.fromJson(Map<String, dynamic> json) {
    return StatusData(
      orderStatus: json['order_status']?.toString() ?? 'pending',
      paymentDeadline: json['payment_deadline']?.toString(),
      isPaid: json['is_paid'] == true || json['is_paid'] == 'true',
    );
  }
}

class AddressDetails {
  final int? addressId;
  final String? address;
  final String? areaName;
  final String? cityName;
  final String? stateName;

  AddressDetails({
    this.addressId,
    this.address,
    this.areaName,
    this.cityName,
    this.stateName,
  });

  factory AddressDetails.fromJson(Map<String, dynamic> json) {
    return AddressDetails(
      addressId: json['address_id'],
      address: json['address']?.toString(),
      areaName: json['area_name']?.toString(),
      cityName: json['city_name']?.toString(),
      stateName: json['state_name']?.toString(),
    );
  }

  String get fullAddress {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (areaName != null) parts.add(areaName!);
    if (cityName != null) parts.add(cityName!);
    if (stateName != null) parts.add(stateName!);
    return parts.join(', ');
  }
}

class OrderDetail {
  final int id;
  final String? orderCode;
  final int whmcsOrderId;
  final int whmcsOrderNumber;
  final String serviceName;
  final String serviceGroup;
  final String invoiceAmount;
  final String invoiceStatus;
  final String serviceStatus;
  final InvoiceDetails invoiceDetails;
  final String billingCycle;
  final String firstPaymentAmount;
  final String recurringAmount;
  final String? nextDueDate;
  final MidtransData midtransData;
  final ProductData productData;
  final StatusData statusData;
  final AddressDetails addressDetails;
  final Map<String, dynamic>? customFields;
  final String createdAt;

  OrderDetail({
    required this.id,
    this.orderCode,
    required this.whmcsOrderId,
    required this.whmcsOrderNumber,
    required this.serviceName,
    required this.serviceGroup,
    required this.invoiceAmount,
    required this.invoiceStatus,
    required this.serviceStatus,
    required this.invoiceDetails,
    required this.billingCycle,
    required this.firstPaymentAmount,
    required this.recurringAmount,
    this.nextDueDate,
    required this.midtransData,
    required this.productData,
    required this.statusData,
    required this.addressDetails,
    this.customFields,
    required this.createdAt,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] ?? 0,
      orderCode: json['order_code']?.toString(),
      whmcsOrderId: json['whmcs_order_id'] ?? 0,
      whmcsOrderNumber: json['whmcs_order_number'] ?? 0,
      serviceName: json['service_name']?.toString() ?? '',
      serviceGroup: json['service_group']?.toString() ?? '',
      invoiceAmount: json['invoice_amount']?.toString() ?? '0',
      invoiceStatus: json['invoice_status']?.toString() ?? 'Unpaid',
      serviceStatus: json['service_status']?.toString() ?? 'Pending',
      invoiceDetails: InvoiceDetails.fromJson(json['invoice_details'] ?? {}),
      billingCycle: json['billing_cycle']?.toString() ?? '',
      firstPaymentAmount: json['first_payment_amount']?.toString() ?? '0',
      recurringAmount: json['recurring_amount']?.toString() ?? '0',
      nextDueDate: json['next_due_date']?.toString(),
      midtransData: MidtransData.fromJson(json['midtrans_data'] ?? {}),
      productData: ProductData.fromJson(json['product_data'] ?? {}),
      statusData: StatusData.fromJson(json['status_data'] ?? {}),
      addressDetails: AddressDetails.fromJson(json['address_details'] ?? {}),
      customFields: json['custom_fields'] as Map<String, dynamic>?,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  // Getters for display
  String get formattedAmount {
    final amount = double.tryParse(invoiceAmount) ?? 0;
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  bool get isPaid => invoiceStatus.toLowerCase() == 'paid';

  String get displayStatus => isPaid ? 'PAID' : 'UNPAID';

  DateTime? get createdDate {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return null;
    }
  }

  String get formattedDate {
    final date = createdDate;
    if (date == null) return 'Unknown date';

    const months = [
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
  }

  // Compatibility methods for existing OrderResponse usage
  String get productName => serviceName;
  String get productDetail => serviceGroup;
  String get midtransOrderId => midtransData.midtransOrderId;
  String get subtotal => invoiceDetails.subtotal;
  String get tax => invoiceDetails.tax;
  String get taxRate => invoiceDetails.taxRate;
  String get credit => invoiceDetails.credit;
  String get total => invoiceDetails.total;

  // Midtrans link compatibility
  MidtransLink get midtransLink =>
      MidtransLink(redirectUrl: midtransData.midtransRedirectUrl);
}

// Helper class for midtrans link compatibility
class MidtransLink {
  final String redirectUrl;

  MidtransLink({required this.redirectUrl});
}

class OrderDetailsResponse {
  final List<OrderDetail> orders;
  final int total;

  OrderDetailsResponse({required this.orders, required this.total});

  factory OrderDetailsResponse.fromJson(Map<String, dynamic> json) {
    final ordersData = json['orders'] as List? ?? [];
    return OrderDetailsResponse(
      orders: ordersData.map((item) => OrderDetail.fromJson(item)).toList(),
      total: json['total'] ?? 0,
    );
  }
}
