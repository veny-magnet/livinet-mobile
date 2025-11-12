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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTicketHeader(),
          _buildReplies(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTicketHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey.shade50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusBadge(ticketDetail!['status'] ?? 'Open'),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _ticketService.formatTicketDate(ticketDetail!['date']),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticketDetail!['title'] ?? 'No Title',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Open Sans',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'ID: ${ticketDetail!['tid'] ?? ticketDetail!['ticketid']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontFamily: 'Open Sans',
                ),
              ),
              if (ticketDetail!['priority'] != null) ...[
                Text(
                  ' • ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  'Priority: ${ticketDetail!['priority']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ],
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'Open Sans',
        ),
      ),
    );
  }

  Widget _buildTicketContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + Name + Date inline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with circle background
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              // Name
              Expanded(
                child: Text(
                  ticketDetail!['name'] ??
                      ticketDetail!['requestor_name'] ??
                      'User',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ),
              // Date
              Text(
                _ticketService.formatTicketDate(ticketDetail!['date']),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontFamily: 'Open Sans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description (indented to align with name)
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(
              ticketDetail!['description'] ?? 'No description available',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.6,
                fontFamily: 'Open Sans',
              ),
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
      return Padding(
        padding: const EdgeInsets.all(40),
        child: const Column(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 48),
            SizedBox(height: 12),
            Text(
              'No replies yet',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'Open Sans',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...replyList.map((reply) => _buildReplyItem(reply)).toList()],
    );
  }

  Widget _buildReplyItem(Map<String, dynamic> reply) {
    final isAdmin = reply['admin']?.toString().isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Name + Date inline
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with circle background
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAdmin ? Icons.support_agent : Icons.person_outline,
                      color: isAdmin ? Colors.blue : Colors.grey.shade600,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name
                  Expanded(
                    child: Text(
                      reply['name'] ?? reply['requestor_name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isAdmin ? Colors.blue : Colors.black87,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                  ),
                  // Date
                  Text(
                    _ticketService.formatTicketDate(reply['date']),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Message (indented to align with name)
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: Text(
                  reply['message'] ?? 'No message',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.6,
                    fontFamily: 'Open Sans',
                  ),
                ),
              ),
            ],
          ),
        ),
        // Divider between replies
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: Colors.grey.shade300, height: 1),
        ),
      ],
    );
  }
}
