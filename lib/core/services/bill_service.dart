import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class BillService {
  BillService._internal();

  static const String _baseUrl = 'https://3580dc107926.ngrok-free.app/api/v1';
  static BillService? _instance;

  static BillService get instance {
    _instance ??= BillService._internal();
    return _instance!;
  }

  Future<Map<String, dynamic>> getBillHistory({
    required String userId,
    int? userAddressId,
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

      final queryParameters = <String, String>{'user_id': userId};
      if (userAddressId != null) {
        queryParameters['user_address_id'] = userAddressId.toString();
      }

      final uri = Uri.parse(
        '$_baseUrl/get/billhistory',
      ).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Bill history retrieved',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to retrieve bill history',
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

  Future<Map<String, dynamic>> getBillHistoryDetail({
    required String invoiceId,
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

      final uri = Uri.parse(
        '$_baseUrl/get/billhistorydetail',
      ).replace(queryParameters: {'invoice_id': invoiceId});

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Bill detail retrieved',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to retrieve bill detail',
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
