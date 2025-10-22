import '../services/base_api_service.dart';
import 'app_logger.dart';
import '../cache/cache_manager.dart';
import '../cache/cache.dart';

class TicketService {
  static final TicketService _instance = TicketService._internal();
  static TicketService get instance => _instance;

  TicketService._internal();

  final BaseApiService _apiService = BaseApiService();
  final _logger = AppLogger.instance;
  final _cacheManager = CacheManager.instance;

  static const String CACHE_VERSION = '1.0.0';

  /// Get ticket history for a user
  /// Cache: networkFirst strategy (tickets can have new replies)
  Future<Map<String, dynamic>> getTicketHistory({
    required String userId,
    String? userAddressId,
    bool forceRefresh = false,
  }) async {
    try {
      _logger.debug(
        'Fetching ticket history for userId: $userId, userAddressId: $userAddressId',
      );

      final cacheKey = 'tickets_${userId}_${userAddressId ?? "all"}';

      // Define cache configuration: 5 min fresh, 30 min stale
      // Use networkFirst to always try API but fall back to cache if offline
      final cacheConfig = CacheConfig(
        maxAge: const Duration(minutes: 5),
        staleAge: const Duration(minutes: 30),
        strategy: CacheStrategy.networkFirst,
        version: CACHE_VERSION,
      );

      final queryParams = <String, String>{'user_id': userId};

      if (userAddressId != null && userAddressId.isNotEmpty) {
        queryParams['user_address_id'] = userAddressId;
      }

      // Try network first
      if (!forceRefresh) {
        try {
          final response = await _apiService.get<Map<String, dynamic>>(
            '/get/tickethistory',
            queryParams: queryParams,
            fromJson: (json) => json as Map<String, dynamic>,
          );

          _logger.debug(
            'Raw API response - success: ${response.success}, message: ${response.message}',
          );

          if (response.success && response.data != null) {
            Map<String, dynamic> responseData;
            if (response.data is Map<String, dynamic>) {
              responseData = response.data as Map<String, dynamic>;
            } else {
              responseData = {'data': response.data};
            }

            // Store in cache
            await _cacheManager.set(cacheKey, responseData, cacheConfig);

            return {
              'success': true,
              'message': response.message,
              'data': responseData,
            };
          }
        } catch (e) {
          _logger.warning('Network request failed, trying cache: $e');
        }
      }

      // Fall back to cache if network failed
      final cached = await _cacheManager.get<Map<String, dynamic>>(
        cacheKey,
        cacheConfig,
        (json) => json,
      );

      if (cached != null) {
        return {
          'success': true,
          'message': 'Ticket history fetched from cache',
          'data': cached.data,
        };
      }

      return {
        'success': false,
        'message': 'Failed to get ticket history',
        'data': null,
      };
    } catch (e) {
      _logger.error('Exception in getTicketHistory', e);
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
    String? userAddressId,
  }) async {
    try {
      _logger.debug(
        'Fetching ticket detail for userId: $userId, ticketId: $ticketId, userAddressId: $userAddressId',
      );

      final queryParams = <String, String>{
        'user_id': userId,
        'ticketid': ticketId,
      };

      if (userAddressId != null && userAddressId.isNotEmpty) {
        queryParams['user_address_id'] = userAddressId;
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/ticketdetail',
        queryParams: queryParams,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.debug('Ticket detail response: ${response.data}');

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
      _logger.error('Error fetching ticket detail', e);
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
      _logger.info('Opening new ticket for userId: $userId, subject: $subject');
      _logger.debug('Message: $message');

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

      _logger.debug('Request body: $body');

      final response = await _apiService.post<Map<String, dynamic>>(
        '/post/ticketopen',
        body: body,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.info(
        'Open ticket response - success: ${response.success}, message: ${response.message}',
      );
      _logger.debug('Open ticket response data: ${response.data}');

      if (response.success) {
        // Clear ticket cache after opening new ticket
        await clearCache(userId: userId, userAddressId: userAddressId);

        return {
          'success': true,
          'message': response.message,
          'data': response.data,
        };
      } else {
        return {'success': false, 'message': response.message, 'data': null};
      }
    } catch (e) {
      _logger.error('Error opening ticket', e);
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
    String? userId,
    String? userAddressId,
  }) async {
    try {
      _logger.info('Replying to ticket: $ticketId, code: $code');
      _logger.debug('Message: $message');

      final response = await _apiService.post<Map<String, dynamic>>(
        '/post/ticketreply',
        body: {'code': code, 'ticketid': ticketId, 'message': message},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.debug('Reply ticket response: ${response.data}');

      if (response.success) {
        // Clear ticket cache after reply
        if (userId != null) {
          await clearCache(userId: userId, userAddressId: userAddressId);
        }

        return {
          'success': true,
          'message': response.message,
          'data': response.data,
        };
      } else {
        return {'success': false, 'message': response.message, 'data': null};
      }
    } catch (e) {
      _logger.error('Error replying to ticket', e);
      return {
        'success': false,
        'message': 'Failed to reply to ticket: $e',
        'data': null,
      };
    }
  }

  /// Clear ticket cache
  Future<void> clearCache({String? userId, String? userAddressId}) async {
    try {
      if (userId != null) {
        final addressPart = userAddressId ?? 'all';
        final cacheKey = 'tickets_${userId}_$addressPart';
        await _cacheManager.invalidate(cacheKey);
        _logger.debug('Cleared ticket cache for: $cacheKey');
      } else {
        await _cacheManager.invalidatePattern(r'^tickets_.*');
        _logger.debug('Cleared all ticket cache');
      }
    } catch (e) {
      _logger.error('Error clearing ticket cache', e);
    }
  }

  /// Parse ticket history data to simplified format
  List<Map<String, dynamic>> parseTicketHistory(Map<String, dynamic> response) {
    try {
      final tickets = <Map<String, dynamic>>[];

      _logger.debug('Parsing response: $response');

      // Handle both nested data response and direct data
      dynamic dataSection = response['data'];

      // If data is the response itself (contains tickets directly)
      if (dataSection != null && dataSection['tickets'] is List) {
        final ticketList = dataSection['tickets'] as List;
        _logger.debug('Found ${ticketList.length} tickets in data.tickets');

        for (final ticket in ticketList) {
          if (ticket is Map<String, dynamic>) {
            final parsedTicket = {
              'ticketid': ticket['ticketid']?.toString() ?? '',
              'tid': ticket['tid']?.toString() ?? '',
              'title': ticket['ticketTitle']?.toString() ?? '',
              'description': ticket['ticketDesc']?.toString() ?? '',
              'date': ticket['date']?.toString() ?? '',
              'status': ticket['status']?.toString() ?? 'Open',
            };
            _logger.debug('Parsed ticket: $parsedTicket');
            tickets.add(parsedTicket);
          }
        }
      }
      // Handle case where response itself contains tickets array
      else if (response['tickets'] is List) {
        final ticketList = response['tickets'] as List;
        _logger.debug('Found ${ticketList.length} tickets in response.tickets');

        for (final ticket in ticketList) {
          if (ticket is Map<String, dynamic>) {
            final parsedTicket = {
              'ticketid': ticket['ticketid']?.toString() ?? '',
              'tid': ticket['tid']?.toString() ?? '',
              'title': ticket['ticketTitle']?.toString() ?? '',
              'description': ticket['ticketDesc']?.toString() ?? '',
              'date': ticket['date']?.toString() ?? '',
              'status': ticket['status']?.toString() ?? 'Open',
            };
            _logger.debug('Parsed ticket: $parsedTicket');
            tickets.add(parsedTicket);
          }
        }
      } else {
        _logger.warning('No tickets array found in response');
        _logger.debug('Response keys: ${response.keys}');
        if (dataSection != null) {
          _logger.debug('Data section keys: ${(dataSection as Map).keys}');
        }
      }

      _logger.debug('Final parsed tickets count: ${tickets.length}');
      return tickets;
    } catch (e) {
      _logger.error('Error parsing ticket history', e);
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
      _logger.error('Error parsing ticket detail', e);
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
