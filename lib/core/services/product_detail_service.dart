import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'app_logger.dart';
import '../config/app_config.dart';
// Cache imports removed - no longer needed

class ProductDetail {
  final String name;
  final String description;
  final String price;
  final Map<String, dynamic> rawData;

  ProductDetail({
    required this.name,
    required this.description,
    required this.price,
    required this.rawData,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '0',
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'rawData': rawData,
    };
  }

  // Formatted price for display
  String get formattedPrice {
    final priceInt = int.tryParse(price) ?? 0;
    return 'Rp ${_formatNumber(priceInt)}';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

class ProductDetailService {
  static final _config = AppConfig.instance;
  static String get baseUrl => _config.baseUrl;
  final _logger = AppLogger.instance;

  static ProductDetailService? _instance;

  ProductDetailService._internal();

  static ProductDetailService get instance {
    _instance ??= ProductDetailService._internal();
    return _instance!;
  }

  /// Get product detail with authentication - NO CACHE
  Future<Map<String, dynamic>> getProductDetail({
    required int productId,
    bool forceRefresh = false,
  }) async {
    try {
      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
          'data': null,
        };
      }

      // Prepare query parameters
      final Uri uri = Uri.parse(
        '$baseUrl/get/productdetail',
      ).replace(queryParameters: {'product_id': productId.toString()});

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
      );

      _logger.debug('Product detail response: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['code'] == 200 && responseData['success'] == true) {
          final Map<String, dynamic> productData =
              responseData['data']['product'] ?? {};

          // Parse the product detail - NO CACHE
          final productDetail = ProductDetail.fromJson(productData);

          return {
            'success': true,
            'data': productDetail,
            'message':
                responseData['message'] ??
                'Product detail fetched successfully',
          };
        } else {
          return {
            'success': false,
            'message':
                responseData['message'] ?? 'Failed to fetch product detail',
            'data': null,
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      _logger.error('Error fetching product detail', e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Cache methods removed - no longer needed
}
