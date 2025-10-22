class BillHistoryRequest {
  final String userId;
  final int userAddressId;

  BillHistoryRequest({required this.userId, required this.userAddressId});

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'user_address_id': userAddressId};
  }
}

class BillHistory {
  final String amount;
  final String paymentStatus;
  final String invoiceStatusWhmcs;
  final String? paymentDate;
  final String invoiceId;
  final String midtransOrderId;
  final int? userAddressId;
  final String createdAt;

  BillHistory({
    required this.amount,
    required this.paymentStatus,
    required this.invoiceStatusWhmcs,
    this.paymentDate,
    required this.invoiceId,
    required this.midtransOrderId,
    this.userAddressId,
    required this.createdAt,
  });

  factory BillHistory.fromJson(Map<String, dynamic> json) {
    return BillHistory(
      amount: json['amount']?.toString() ?? '0',
      paymentStatus: json['payment_status']?.toString() ?? 'UNPAID',
      invoiceStatusWhmcs: json['invoice_status_whmcs']?.toString() ?? 'unpaid',
      paymentDate: json['payment_date']?.toString(),
      invoiceId: json['invoice_id']?.toString() ?? '',
      midtransOrderId: json['midtrans_order_id']?.toString() ?? '',
      userAddressId: json['user_address_id'] != null
          ? int.tryParse(json['user_address_id'].toString())
          : null,
      createdAt:
          json['create_at']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }

  String get formattedAmount {
    final amount = double.tryParse(this.amount) ?? 0;
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';

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

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'payment_status': paymentStatus,
      'invoice_status_whmcs': invoiceStatusWhmcs,
      'payment_date': paymentDate,
      'invoice_id': invoiceId,
      'midtrans_order_id': midtransOrderId,
      'user_address_id': userAddressId,
      'created_at': createdAt,
    };
  }
}
