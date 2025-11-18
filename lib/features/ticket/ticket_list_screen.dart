import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'make_ticket_screen.dart';
import 'ticket_detail_screen.dart';
import '../../core/services/ticket_service.dart';
import '../../core/services/auth_service.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TicketService _ticketService = TicketService.instance;
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> tickets = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final userInfo = await _authService.getCurrentUser();
      final userCode = userInfo?['code']?.toString(); // UUID dari login

      if (userCode == null) {
        throw Exception('User code not found');
      }

      final response = await _ticketService.getTicketHistory(userId: userCode);

      if (response['success']) {
        final parsedTickets = _ticketService.parseTicketHistory(response);
        setState(() {
          tickets = parsedTickets;
          isLoading = false;
        });
      } else {
        setState(() {
          error = response['message'] ?? 'Failed to load tickets';
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            'Ticket',
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
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We will respond within 3 business days up to on receiving your ticket.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontFamily: 'Open Sans',
                    ),
                  ),
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 4, bottom: 12),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MakeTicketScreen(),
                    ),
                  ).then((result) {
                    // Refresh tickets if new ticket was created
                    if (result == true) {
                      _loadTickets();
                    }
                  });
                },
                icon: const Icon(
                  CupertinoIcons.tickets,
                  color: Colors.green,
                  size: 18,
                ),
                label: const Text(
                  'Make Ticket',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Open Sans',
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ),

          Container(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicator: const BoxDecoration(color: Colors.transparent),
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.green,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Open Sans',
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Open Sans',
                  ),
                  tabs: const [
                    Tab(text: 'Ongoing'),
                    Tab(text: 'Completed'),
                  ],
                ),
                Container(
                  height: 3,
                  margin: const EdgeInsets.only(top: 0),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CB04C), Color(0xFFF8D86E)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    indicatorColor: Colors.transparent,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.transparent,
                    unselectedLabelColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: 'Ongoing'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildOngoingTab(), _buildAnsweredTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E22)),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            Text(
              'Error loading tickets',
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
              onPressed: _loadTickets,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final ongoingTickets = tickets
        .where((ticket) => ticket['status']?.toLowerCase() == 'open')
        .toList();

    if (ongoingTickets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              'No ongoing tickets',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ongoingTickets.length,
          separatorBuilder: (context, index) =>
              Divider(color: Colors.grey.shade300, height: 24, thickness: 1),
          itemBuilder: (context, index) {
            final ticket = ongoingTickets[index];
            return _buildTicketItem(
              ticketId: ticket['ticketid'] ?? '',
              date: _ticketService.formatTicketDate(ticket['date']),
              time: '',
              title: ticket['title'] ?? 'No Title',
              description: ticket['description'] ?? 'No Description',
              status: ticket['status'] ?? 'Open',
              isOngoing: true,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnsweredTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E22)),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            Text(
              'Error loading tickets',
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
              onPressed: _loadTickets,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final answeredTickets = tickets
        .where((ticket) => ticket['status']?.toLowerCase() == 'answered')
        .toList();

    if (answeredTickets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.question_answer, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              'No answered tickets',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: answeredTickets.length,
          separatorBuilder: (context, index) =>
              Divider(color: Colors.grey.shade300, height: 24, thickness: 1),
          itemBuilder: (context, index) {
            final ticket = answeredTickets[index];
            return _buildTicketItem(
              ticketId: ticket['ticketid'] ?? '',
              date: _ticketService.formatTicketDate(ticket['date']),
              time: '',
              title: ticket['title'] ?? 'No Title',
              description: ticket['description'] ?? 'No Description',
              status: ticket['status'] ?? 'Answered',
              isOngoing: false,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTicketItem({
    String? ticketId,
    required String date,
    required String time,
    required String title,
    required String description,
    required bool isOngoing,
    String? status,
  }) {
    return GestureDetector(
      onTap: () {
        if (ticketId != null && ticketId.isNotEmpty) {
          // TODO: Navigate to ticket detail screen
          _showTicketDetail(ticketId);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time and Date on top
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontFamily: 'Open Sans',
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontFamily: 'Open Sans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Open Sans',
            ),
          ),
          const SizedBox(height: 4),

          // Description with arrow
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'Open Sans',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  void _showTicketDetail(String ticketId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TicketDetailScreen(ticketId: ticketId, title: 'Ticket Detail'),
      ),
    );
  }
}
