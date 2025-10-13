import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/order_summary.dart';
import 'auth_service.dart';

class OrderService {
  OrderService._internal();

  static const String _baseUrl = 'https://3580dc107926.ngrok-free.app/api/v1';
  static OrderService? _instance;

  static OrderService get instance {
    _instance ??= OrderService._internal();
    return _instance!;
  }

  Future<Map<String, dynamic>> createOrder({
    required String userId,
    required int productId,
    required int userAddressId,
    required String level,
    required String block,
    required String unitNumber,
  }) async {
    try {
      final authService = AuthService();
      final token = await authService.getAuthToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
          'data': null,
        };
      }

      final uri = Uri.parse('$_baseUrl/insert/order');
      final payload = {
        'user_id': userId,
        'product_id': productId,
        'user_address_id': userAddressId,
        'level': level,
        'block': block,
        'unit_number': unitNumber,
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(payload),
      );

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>?;
        if (data == null) {
          return {
            'success': false,
            'message': 'Order response missing data payload',
            'data': null,
          };
        }

        final summary = OrderSummary.fromApi(data);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Order created successfully',
          'data': summary,
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to create order',
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }
}
