import '../services/base_api_service.dart';

class TicketService {
  static final TicketService _instance = TicketService._internal();
  static TicketService get instance => _instance;

  TicketService._internal();

  final BaseApiService _apiService = BaseApiService();

  /// Get ticket history for a user
  Future<Map<String, dynamic>> getTicketHistory({
    required String userId,
  }) async {
    try {
      print('TicketService: Fetching ticket history for userId: $userId');

      final response = await _apiService.get(
        '/get/tickethistory',
        queryParams: {'user_id': userId},
      );

      print('TicketService: Ticket history response: ${response.data}');

      if (response.success && response.data != null) {
        return {
          'success': true,
          'message': response.message,
          'data': response.data,
        };
      } else {
        return {'success': false, 'message': response.message, 'data': null};
      }
    } catch (e) {
      print('TicketService: Error fetching ticket history: $e');
      return {
        'success': false,
        'message': 'Failed to get ticket history: $e',
        'data': null,
      };
    }
  }

  /// Get detailed information for a specific ticket
  Future<Map<String, dynamic>> getTicketDetail({
    required String userId,
    required String ticketId,
  }) async {
    try {
      print(
        'TicketService: Fetching ticket detail for userId: $userId, ticketId: $ticketId',
      );

      final response = await _apiService.get(
        '/get/ticketdetail',
        queryParams: {'user_id': userId, 'ticketid': ticketId},
      );

      print('TicketService: Ticket detail response: ${response.data}');

      if (response.success && response.data != null) {
        return {
          'success': true,
          'message': response.message,
          'data': response.data,
        };
      } else {
        return {'success': false, 'message': response.message, 'data': null};
      }
    } catch (e) {
      print('TicketService: Error fetching ticket detail: $e');
      return {
        'success': false,
        'message': 'Failed to get ticket detail: $e',
        'data': null,
      };
    }
  }

  /// Open a new ticket
  Future<Map<String, dynamic>> openTicket({
    required String userId,
    required String subject,
    required String message,
    String? userAddressId,
    String? subsPlanId,
    String? date,
  }) async {
    try {
      print('TicketService: Opening new ticket for userId: $userId');
      print('TicketService: Subject: $subject');
      print('TicketService: Message: $message');

      final body = <String, dynamic>{
        'user_id': userId,
        'subject': subject,
        'message': message,
      };

      // Add optional parameters if provided
      if (userAddressId != null && userAddressId.isNotEmpty) {
        body['userAddressID'] = userAddressId;
      }
      if (subsPlanId != null && subsPlanId.isNotEmpty) {
        body['subsPlanID'] = subsPlanId;
      }
      if (date != null && date.isNotEmpty) {
        body['date'] = date;
      }

      print('TicketService: Request body: $body');

      final response = await _apiService.post('/post/ticketopen', body: body);

      print('TicketService: Open ticket response: ${response.data}');

      if (response.success && response.data != null) {
        return {
          'success': true,
          'message': response.message,
          'data': response.data,
        };
      } else {
        return {'success': false, 'message': response.message, 'data': null};
      }
    } catch (e) {
      print('TicketService: Error opening ticket: $e');
      return {
        'success': false,
        'message': 'Failed to open ticket: $e',
        'data': null,
      };
    }
  }

  /// Reply to an existing ticket
  Future<Map<String, dynamic>> replyTicket({
    required String code,
    required String ticketId,
    required String message,
  }) async {
    try {
      print('TicketService: Replying to ticket: $ticketId');
      print('TicketService: Code: $code');
      print('TicketService: Message: $message');

      final response = await _apiService.post(
        '/post/ticketreply',
        body: {'code': code, 'ticketid': ticketId, 'message': message},
      );

      print('TicketService: Reply ticket response: ${response.data}');

      if (response.success && response.data != null) {
        return {
          'success': true,
          'message': response.message,
          'data': response.data,
        };
      } else {
        return {'success': false, 'message': response.message, 'data': null};
      }
    } catch (e) {
      print('TicketService: Error replying to ticket: $e');
      return {
        'success': false,
        'message': 'Failed to reply to ticket: $e',
        'data': null,
      };
    }
  }

  /// Parse ticket history data to simplified format
  List<Map<String, dynamic>> parseTicketHistory(Map<String, dynamic> response) {
    try {
      final tickets = <Map<String, dynamic>>[];

      if (response['data'] != null) {
        final data = response['data'];

        if (data['tickets'] is List) {
          final ticketList = data['tickets'] as List;

          for (final ticket in ticketList) {
            if (ticket is Map<String, dynamic>) {
              tickets.add({
                'ticketid': ticket['ticketid']?.toString() ?? '',
                'tid': ticket['tid']?.toString() ?? '',
                'title': ticket['ticketTitle']?.toString() ?? '',
                'description': ticket['ticketDesc']?.toString() ?? '',
                'date': ticket['date']?.toString() ?? '',
                'status': ticket['status']?.toString() ?? 'Open',
              });
            }
          }
        }
      }

      print('TicketService: Parsed ${tickets.length} tickets');
      return tickets;
    } catch (e) {
      print('TicketService: Error parsing ticket history: $e');
      return [];
    }
  }

  /// Parse ticket detail data
  Map<String, dynamic>? parseTicketDetail(Map<String, dynamic> response) {
    try {
      if (response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        return {
          'ticketid': data['ticketid']?.toString() ?? '',
          'tid': data['tid']?.toString() ?? '',
          'title': data['ticketTitle']?.toString() ?? '',
          'description': data['ticketDesc']?.toString() ?? '',
          'date': data['date']?.toString() ?? '',
          'status': data['status']?.toString() ?? 'Open',
          'priority': data['priority']?.toString() ?? '',
          'replies': data['replies'] ?? [],
        };
      }

      return null;
    } catch (e) {
      print('TicketService: Error parsing ticket detail: $e');
      return null;
    }
  }

  /// Format date for display
  String formatTicketDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Unknown date';
    }

    try {
      final date = DateTime.parse(dateString);
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
      return dateString; // Return original if parsing fails
    }
  }

  /// Get status color for UI
  String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return '#E67E22'; // Orange
      case 'answered':
        return '#3498DB'; // Blue
      case 'customer-reply':
        return '#F39C12'; // Yellow
      case 'closed':
        return '#27AE60'; // Green
      case 'on-hold':
        return '#95A5A6'; // Gray
      default:
        return '#BDC3C7'; // Light gray
    }
  }

  /// Get status display text
  String getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'answered':
        return 'Answered';
      case 'customer-reply':
        return 'Customer Reply';
      case 'closed':
        return 'Closed';
      case 'on-hold':
        return 'On Hold';
      default:
        return status.toUpperCase();
    }
  }
}
