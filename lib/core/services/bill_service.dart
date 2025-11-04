import '../services/base_api_service.dart';
import '../models/bill_models.dart';
import 'app_logger.dart';

class BillService {
  static final BillService _instance = BillService._internal();
  static BillService get instance => _instance;

  BillService._internal();

  final BaseApiService _apiService = BaseApiService();
  final _logger = AppLogger.instance;

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
    bool forceRefresh = false, // Kept for API compatibility
  }) async {
    try {
      // NO CACHE - Always fetch fresh from API
      final response = await _apiService.get<List<BillHistory>>(
        '/get/billhistory',
        headers: _getHeaders(authToken),
        queryParams: {
          'user_id': request.userId,
          'user_address_id': request.userAddressId.toString(),
        },
        fromJson: (json) {
          _logger.debug('Raw API response: $json');
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
              _logger.warning('Unexpected response structure: $json');
              return <BillHistory>[];
            }

            final bills = billsData
                .map(
                  (item) => BillHistory.fromJson(item as Map<String, dynamic>),
                )
                .toList();

            _logger.debug('Parsed ${bills.length} bills successfully');
            return bills;
          } catch (e) {
            _logger.error('Error parsing bill history', e);
            return <BillHistory>[];
          }
        },
      );

      if (response.success) {
        final bills = response.data ?? <BillHistory>[];

        return {
          'success': true,
          'message': response.message,
          'data': bills,
          'source': 'api',
        };
      } else {
        _logger.warning('API returned error: ${response.message}');
        return {
          'success': false,
          'message': response.message,
          'data': <BillHistory>[],
        };
      }
    } catch (e) {
      _logger.error('Exception in getBillHistory', e);
      return {
        'success': false,
        'message': 'Failed to get bill history: $e',
        'data': <BillHistory>[],
      };
    }
  }

  // Cache methods removed - no longer needed without cache system

  /// Get detailed bill information
  Future<Map<String, dynamic>> getBillHistoryDetail({
    required String invoiceId,
    required String userId,
    String? authToken,
    int retryCount = 0,
  }) async {
    const maxRetries = 2;

    try {
      _logger.debug(
        'Fetching bill detail for invoice $invoiceId, user $userId (attempt ${retryCount + 1})',
      );

      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/billhistorydetail',
        headers: _getHeaders(authToken),
        queryParams: {'invoice_id': invoiceId, 'user_id': userId},
        fromJson: (json) {
          _logger.debug('Raw response from API: $json');
          if (json is Map<String, dynamic>) {
            return json;
          } else {
            _logger.warning('Unexpected response type: ${json.runtimeType}');
            return <String, dynamic>{};
          }
        },
      );

      _logger.debug(
        'Response success: ${response.success}, data is null: ${response.data == null}',
      );
      _logger.debug('Response message: ${response.message}');

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      final responseData = response.data!;
      _logger.debug('Response data keys: ${responseData.keys}');

      final isSuccess =
          response.success ||
          responseData['success'] == true ||
          responseData['code'] == 200;

      if (!isSuccess) {
        throw Exception('API returned error: ${response.message}');
      }

      // Transform the response
      final transformedData = _transformBillDetailResponse(responseData);

      return transformedData;
    } catch (e) {
      // Retry on connection errors
      if (retryCount < maxRetries &&
          (e.toString().contains('Connection closed') ||
              e.toString().contains('SocketException') ||
              e.toString().contains('TimeoutException'))) {
        _logger.info('Retrying bill detail request in 2 seconds');
        await Future.delayed(const Duration(seconds: 2));

        return await getBillHistoryDetail(
          invoiceId: invoiceId,
          userId: userId,
          authToken: authToken,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    }
  }

  /// Transform the API response structure to make it more usable
  Map<String, dynamic> _transformBillDetailResponse(
    Map<String, dynamic> responseData,
  ) {
    try {
      _logger.debug('Transform - Input data: $responseData');
      _logger.debug('Transform - Input keys: ${responseData.keys}');

      // Extract the main data structure
      final data = responseData['data'] as Map<String, dynamic>?;
      _logger.debug('Transform - data keys: ${data?.keys}');

      if (data == null) {
        _logger.warning('Transform - No data found');
        return responseData;
      }

      // Check if invoices are in data.data.invoices or data.invoices
      dynamic invoices;
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        // Structure: {data: {data: {invoices: [...]}}}
        final innerData = data['data'] as Map<String, dynamic>;
        _logger.debug('Transform - innerData keys: ${innerData.keys}');
        invoices = innerData['invoices'] as List<dynamic>?;
      } else if (data.containsKey('invoices')) {
        // Structure: {data: {invoices: [...]}}
        invoices = data['invoices'] as List<dynamic>?;
      }

      _logger.debug('Transform - invoices count: ${invoices?.length}');

      if (invoices == null || invoices.isEmpty) {
        _logger.warning('Transform - No invoices found');
        return responseData;
      }

      final invoice = invoices.first as Map<String, dynamic>;
      _logger.debug('Transform - invoice keys: ${invoice.keys}');

      final items = invoice['items'] as List<dynamic>? ?? [];
      _logger.debug('Transform - items count: ${items.length}');

      // Extract service details from items
      final List<Map<String, dynamic>> serviceDetails = [];
      final List<Map<String, dynamic>> invoiceItems = [];

      for (int i = 0; i < items.length; i++) {
        final itemMap = items[i] as Map<String, dynamic>;
        invoiceItems.add(itemMap);

        // If item has service details, add to serviceDetails
        if (itemMap['service'] != null) {
          final service = itemMap['service'] as Map<String, dynamic>;
          _logger.debug('Transform - Found service in item $i');
          _logger.debug('Transform - Service keys: ${service.keys}');
          serviceDetails.add(service);
        } else {
          _logger.debug(
            'Transform - No service in item $i (${itemMap['type']})',
          );
        }
      }

      _logger.debug(
        'Transform - Total serviceDetails found: ${serviceDetails.length}',
      );

      final result = {
        'invoice': invoice,
        'invoiceitems': invoiceItems,
        'servicedetails': serviceDetails,
        'midtrans': {
          'code': data['code'],
          'midtransclient': data['midtransclient'],
          'merchantbaseurl': data['merchantbaseurl'],
          'midtransorderid': data['midtransorderid'],
          'midtransLink': data['midtransLink'],
          'midtranstoken': data['midtranstoken'],
        },
        'raw_response': responseData,
      };

      _logger.debug('Transform - Final result keys: ${result.keys}');
      _logger.debug('Transform - Invoice items count: ${invoiceItems.length}');
      _logger.debug(
        'Transform - Service details count: ${serviceDetails.length}',
      );

      return result;
    } catch (e, stackTrace) {
      _logger.error('Error transforming bill detail response', e, stackTrace);
      return responseData;
    }
  }

  /// Get detailed bill information using BillHistory object
  Future<Map<String, dynamic>> getBillHistoryDetailFromBill({
    required BillHistory billHistory,
    required String userId,
    String? authToken,
  }) async {
    return await getBillHistoryDetail(
      invoiceId: billHistory.invoiceId,
      userId: userId,
      authToken: authToken,
    );
  }
}
