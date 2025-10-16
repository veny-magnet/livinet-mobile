import 'package:flutter/material.dart';
import '../../core/services/ticket_service.dart';
import '../../core/services/auth_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final String title;

  const TicketDetailScreen({
    Key? key,
    required this.ticketId,
    required this.title,
  }) : super(key: key);

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TicketService _ticketService = TicketService.instance;
  final AuthService _authService = AuthService();

  Map<String, dynamic>? ticketDetail;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadTicketDetail();
  }

  Future<void> _loadTicketDetail() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final userInfo = await _authService.getCurrentUser();
      final userId = userInfo?['user_id']?.toString();

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await _ticketService.getTicketDetail(
        userId: userId,
        ticketId: widget.ticketId,
      );

      if (response['success']) {
        final parsedDetail = _ticketService.parseTicketDetail(response);
        setState(() {
          ticketDetail = parsedDetail;
          isLoading = false;
        });
      } else {
        setState(() {
          error = response['message'] ?? 'Failed to load ticket detail';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
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
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Open Sans',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        titleSpacing: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E22)),
              ),
            )
          : error != null
          ? _buildErrorWidget()
          : ticketDetail != null
          ? _buildTicketDetailContent()
          : _buildNoDataWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 64),
          const SizedBox(height: 16),
          Text(
            'Error loading ticket detail',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTicketDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent, color: Colors.grey, size: 64),
          SizedBox(height: 16),
          Text(
            'No ticket detail found',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetailContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTicketHeader(),
          const SizedBox(height: 24),
          _buildTicketContent(),
          const SizedBox(height: 24),
          _buildReplies(),
        ],
      ),
    );
  }

  Widget _buildTicketHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticketDetail!['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildStatusBadge(ticketDetail!['status'] ?? 'Open'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.confirmation_number,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'ID: ${ticketDetail!['tid'] ?? ticketDetail!['ticketid']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.grey[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Date: ${_ticketService.formatTicketDate(ticketDetail!['date'])}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          if (ticketDetail!['priority'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.priority_high, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Priority: ${ticketDetail!['priority']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'open':
        statusColor = Colors.orange;
        break;
      case 'answered':
        statusColor = Colors.blue;
        break;
      case 'closed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor),
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

  Widget _buildTicketContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ticketDetail!['description'] ?? 'No description available',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplies() {
    final replies = ticketDetail!['replies'];

    if (replies == null) {
      return const SizedBox.shrink();
    }

    List<dynamic> replyList = [];
    if (replies is Map && replies['reply'] is List) {
      replyList = replies['reply'];
    } else if (replies is List) {
      replyList = replies;
    }

    if (replyList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 48),
            SizedBox(height: 12),
            Text(
              'No replies yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Replies',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...replyList.map((reply) => _buildReplyItem(reply)).toList(),
        ],
      ),
    );
  }

  Widget _buildReplyItem(Map<String, dynamic> reply) {
    final isAdmin = reply['admin']?.toString().isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAdmin
            ? Colors.blue.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAdmin
              ? Colors.blue.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: isAdmin ? Colors.blue : Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reply['name'] ?? reply['requestor_name'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isAdmin ? Colors.blue : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                _ticketService.formatTicketDate(reply['date']),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          if (reply['requestor_type'] != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isAdmin
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reply['requestor_type'],
                style: TextStyle(
                  color: isAdmin ? Colors.blue : Colors.grey[700],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            reply['message'] ?? 'No message',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
