import '../services/base_api_service.dart';
import '../models/order_models.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  static OrderService get instance => _instance;
  
  OrderService._internal();

  final BaseApiService _apiService = BaseApiService();

  Future<Map<String, dynamic>> createOrder(OrderRequest request) async {
    try {
      final response = await _apiService.post<OrderResponse>(
        '/insert/order',
        body: request.toJson(),
        fromJson: (json) => OrderResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        return {
          'success': true,
          'message': response.message,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.message,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create order: $e',
      };
    }
  }
}