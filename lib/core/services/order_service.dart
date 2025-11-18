import '../services/base_api_service.dart';
import '../models/order_models.dart';
import 'app_logger.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  static OrderService get instance => _instance;

  OrderService._internal();

  final BaseApiService _apiService = BaseApiService();
  final _logger = AppLogger.instance;

  Future<Map<String, dynamic>> createOrder(OrderRequest request) async {
    try {
      final requestBody = request.toJson();

      // Log request body for debugging
      _logger.debug('Creating order with request: $requestBody');

      final response = await _apiService.post<OrderResponse>(
        '/insert/order',
        body: requestBody,
        fromJson: (json) => OrderResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        return {
          'success': true,
          'message': response.message,
          'data': response.data,
        };
      } else {
        return {'success': false, 'message': response.message};
      }
    } catch (e) {
      _logger.error('Failed to create order', e);
      return {'success': false, 'message': 'Failed to create order: $e'};
    }
  }
}
