import 'package:flutter/material.dart';
import '../../core/services/bill_service.dart';
import '../../core/services/auth_service.dart';

class BillDetailScreen extends StatefulWidget {
  final String invoiceId;
  final String invoiceNumber;
  final String date;
  final String amount;
  final String status;

  const BillDetailScreen({
    Key? key,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.date,
    required this.amount,
    required this.status,
  }) : super(key: key);

  @override
  _BillDetailScreenState createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  final BillService _billService = BillService.instance;
  final AuthService _authService = AuthService();

  Map<String, dynamic>? billDetail;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadBillDetail();
  }

  Future<void> _loadBillDetail() async {
    try {
      if (!mounted) return; // Check if widget is still mounted

      setState(() {
        isLoading = true;
        error = null;
      });

      final userInfo = await _authService.getCurrentUser();
      final userId = userInfo?['user_id']?.toString();
      final authToken = await _authService.getAuthToken();

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final detail = await _billService.getBillHistoryDetail(
        invoiceId: widget.invoiceId,
        userId: userId,
        authToken: authToken,
      );

      if (!mounted) return; // Check again before setState

      setState(() {
        billDetail = detail;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Check again before setState

      // Parse error message to be more user-friendly
      String errorMessage = 'Unable to load invoice details';

      final errorString = e.toString();
      if (errorString.contains('500')) {
        errorMessage = 'Server error. Please try again later.';
      } else if (errorString.contains('404')) {
        errorMessage = 'Invoice not found.';
      } else if (errorString.contains('401') || errorString.contains('403')) {
        errorMessage = 'Authentication error. Please login again.';
      } else if (errorString.contains('timeout') ||
          errorString.contains('SocketException')) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      }

      setState(() {
        error = errorMessage;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Invoice Details',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Open Sans',
            ),
          ),
        ),
        titleSpacing: 0,
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CB04C)),
              ),
            )
          : error != null
          ? _buildErrorWidget()
          : billDetail != null
          ? _buildBillDetailContent()
          : _buildNoDataWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            const Text(
              'Error loading invoice details',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Open Sans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'Open Sans',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBillDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CB04C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white, fontFamily: 'Open Sans'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_outlined, color: Colors.grey[400], size: 64),
          const SizedBox(height: 16),
          Text(
            'No invoice details found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Open Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillDetailContent() {
    final invoice = billDetail?['invoice'];
    if (invoice == null) return _buildNoDataWidget();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInvoiceHeader(invoice),
          const SizedBox(height: 16),
          _buildFinancialSummary(invoice),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
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
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildInvoiceHeader(Map<String, dynamic> invoice) {
    final status = invoice['status']?.toString() ?? 'Unknown';
    final invoiceNum =
        invoice['invoicenum']?.toString() ?? widget.invoiceNumber;
    final date = invoice['date']?.toString() ?? '';
    final dueDate = invoice['duedate']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Number',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#$invoiceNum',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Date',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(date),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Due Date',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(dueDate),
                      style: TextStyle(
                        color: status.toLowerCase() == 'unpaid'
                            ? Colors.red[700]
                            : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'unpaid':
        statusColor = Colors.red;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(Map<String, dynamic> invoice) {
    final subtotal = invoice['subtotal']?.toString() ?? '0';
    final tax = invoice['tax']?.toString() ?? '0';
    final taxRate = invoice['taxrate']?.toString() ?? '0';
    final total = invoice['total']?.toString() ?? '0';
    final balance = invoice['balance']?.toString() ?? total;
    final amountPaid = invoice['amountPaid']?.toString() ?? '0';
    final paymentMethod =
        invoice['paymentGatewayName']?.toString() ??
        invoice['paymentmethod']?.toString() ??
        'N/A';
    final credit = invoice['credit']?.toString() ?? '0';

    // Get items from billDetail
    final items = billDetail?['invoiceitems'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Open Sans',
            ),
          ),
          const SizedBox(height: 16),

          // Payment Method
          _buildInfoRow('Payment Method', paymentMethod),
          const SizedBox(height: 8),

          // Items breakdown
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Invoice Items:',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Open Sans',
              ),
            ),
            const SizedBox(height: 8),
            ...items.asMap().entries.map((entry) {
              final item = entry.value as Map<String, dynamic>;
              final description = item['description']?.toString() ?? '';
              final amount = item['amount']?.toString() ?? '0';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('  • ', style: TextStyle(color: Colors.black54)),
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ),
                    Text(
                      _formatCurrency(amount),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
          ],

          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),

          // Financial breakdown
          _buildSummaryRow('Subtotal', subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('Tax ($taxRate%)', tax),

          // Credit if any
          if (double.tryParse(credit) != null &&
              double.tryParse(credit)! > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Credit',
              credit,
              valueColor: const Color(0xFF4CB04C),
            ),
          ],

          // Amount paid if any
          if (double.tryParse(amountPaid) != null &&
              double.tryParse(amountPaid)! > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Amount Paid',
              amountPaid,
              valueColor: const Color(0xFF4CB04C),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),

          // Total and Balance
          _buildSummaryRow('Total Amount', total, isTotal: true),
          if (balance != total) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Balance Due',
              balance,
              isTotal: true,
              valueColor: Colors.red[700]!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontFamily: 'Open Sans',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Open Sans',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    String formattedValue = _formatCurrency(value);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black87 : Colors.black54,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Open Sans',
          ),
        ),
        Text(
          formattedValue,
          style: TextStyle(
            color: valueColor ?? (isTotal ? Colors.black87 : Colors.black87),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontFamily: 'Open Sans',
          ),
        ),
      ],
    );
  }

  String _formatCurrency(String value) {
    try {
      final amount = double.tryParse(value) ?? 0;
      return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    } catch (e) {
      return 'Rp $value';
    }
  }
}
