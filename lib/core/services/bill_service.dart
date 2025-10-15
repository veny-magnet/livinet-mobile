import '../services/base_api_service.dart';
import '../models/bill_models.dart';

class BillService {
  static final BillService _instance = BillService._internal();
  static BillService get instance => _instance;

  BillService._internal();

  final BaseApiService _apiService = BaseApiService();

  // Cache management
  final Map<String, List<BillHistory>> _cachedBills = {};
  final Map<String, DateTime> _lastFetch = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Add proper headers with authentication
  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getBillHistory(
    BillHistoryRequest request, {
    String? authToken, // Add auth token parameter
    bool forceRefresh = false, // Add force refresh option
  }) async {
    try {
      final cacheKey = 'bills_${request.userId}_${request.userAddressId}';

      // Check cache first (unless force refresh)
      if (!forceRefresh && _cachedBills.containsKey(cacheKey)) {
        final lastFetch = _lastFetch[cacheKey];
        if (lastFetch != null &&
            DateTime.now().difference(lastFetch) < _cacheExpiry) {
          print('Returning cached bill history for: $cacheKey');
          return {
            'success': true,
            'message': 'Bills fetched from cache',
            'data': _cachedBills[cacheKey] ?? <BillHistory>[],
            'source': 'cache',
          };
        }
      }

      print(
        'Requesting bill history for user: ${request.userId}, address: ${request.userAddressId}',
      );

      final response = await _apiService.get<List<BillHistory>>(
        '/get/billhistory',
        headers: _getHeaders(authToken),
        queryParams: {
          'user_id': request.userId,
          'user_address_id': request.userAddressId.toString(),
        },
        fromJson: (json) {
          print('Raw API response: $json');
          try {
            List<dynamic> billsData;

            // Handle different response structures
            if (json is Map<String, dynamic> && json['data'] is List) {
              // Structure: {code: 200, success: true, data: [...]}
              billsData = json['data'] as List;
            } else if (json is List) {
              // Direct array response: [{...}, {...}]
              billsData = json;
            } else {
              print('Unexpected response structure: $json');
              return <BillHistory>[];
            }

            final bills = billsData
                .map(
                  (item) => BillHistory.fromJson(item as Map<String, dynamic>),
                )
                .toList();

            print('Parsed ${bills.length} bills successfully');
            return bills;
          } catch (e) {
            print('Error parsing bill history: $e');
            return <BillHistory>[];
          }
        },
      );

      if (response.success) {
        // Update cache
        final bills = response.data ?? <BillHistory>[];
        _cachedBills[cacheKey] = bills;
        _lastFetch[cacheKey] = DateTime.now();

        return {
          'success': true,
          'message': response.message,
          'data': bills,
          'source': 'api',
        };
      } else {
        print('API returned error: ${response.message}');
        return {
          'success': false,
          'message': response.message,
          'data': <BillHistory>[],
        };
      }
    } catch (e) {
      print('Exception in getBillHistory: $e');
      return {
        'success': false,
        'message': 'Failed to get bill history: $e',
        'data': <BillHistory>[],
      };
    }
  }

  /// Clear cached bills
  void clearCache({String? userId, int? addressId}) {
    if (userId != null && addressId != null) {
      final cacheKey = 'bills_${userId}_$addressId';
      _cachedBills.remove(cacheKey);
      _lastFetch.remove(cacheKey);
      print('Cleared bill cache for: $cacheKey');
    } else if (userId != null) {
      // Clear all cache entries for this user
      final keysToRemove = _cachedBills.keys
          .where((key) => key.startsWith('bills_$userId'))
          .toList();

      for (final key in keysToRemove) {
        _cachedBills.remove(key);
        _lastFetch.remove(key);
      }
      print('Cleared all bill cache for user: $userId');
    } else {
      // Clear all cache
      _cachedBills.clear();
      _lastFetch.clear();
      print('Cleared all bill cache');
    }
  }

  /// Force refresh bills (bypass cache)
  Future<Map<String, dynamic>> refreshBillHistory(
    BillHistoryRequest request, {
    String? authToken,
  }) async {
    return await getBillHistory(
      request,
      authToken: authToken,
      forceRefresh: true,
    );
  }

  /// Get detailed bill information
  Future<Map<String, dynamic>> getBillHistoryDetail({
    required String invoiceId,
    required String userId,
    String? authToken,
  }) async {
    try {
      print(
        'BillService: Fetching bill detail for invoice $invoiceId, user $userId',
      );

      final response = await _apiService.get(
        '/billhistorydetail',
        queryParams: {'invoice_id': invoiceId, 'user_id': userId},
      );

      print('BillService: Bill detail response: ${response.data}');

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch bill detail: ${response.message}');
      }
    } catch (e) {
      print('BillService: Error fetching bill detail: $e');
      rethrow;
    }
  }
}
