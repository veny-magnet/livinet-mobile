import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

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
  static const String baseUrl = 'https://3580dc107926.ngrok-free.app/api/v1';

  static ProductDetailService? _instance;
  Map<int, ProductDetail> _cachedDetails = {};
  Map<int, DateTime> _lastFetch = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);

  ProductDetailService._internal();

  static ProductDetailService get instance {
    _instance ??= ProductDetailService._internal();
    return _instance!;
  }

  /// Get product detail with authentication
  Future<Map<String, dynamic>> getProductDetail({
    required int productId,
  }) async {
    try {
      // Check cache first
      if (_cachedDetails.containsKey(productId) &&
          _lastFetch.containsKey(productId) &&
          DateTime.now().difference(_lastFetch[productId]!) < _cacheExpiry) {
        return {
          'success': true,
          'data': _cachedDetails[productId],
          'message': 'Product detail fetched from cache',
        };
      }

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

      print('ProductDetailService - Response status: ${response.statusCode}');
      print('ProductDetailService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['code'] == 200 && responseData['success'] == true) {
          final Map<String, dynamic> productData =
              responseData['data']['product'] ?? {};

          // Cache the product detail
          final productDetail = ProductDetail.fromJson(productData);
          _cachedDetails[productId] = productDetail;
          _lastFetch[productId] = DateTime.now();

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
      print('ProductDetailService - Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Clear cached product details
  void clearCache() {
    _cachedDetails.clear();
    _lastFetch.clear();
  }

  /// Get cached product detail without making API call
  ProductDetail? getCachedProductDetail(int productId) {
    if (_cachedDetails.containsKey(productId) &&
        _lastFetch.containsKey(productId) &&
        DateTime.now().difference(_lastFetch[productId]!) < _cacheExpiry) {
      return _cachedDetails[productId];
    }
    return null;
  }

  /// Force refresh product detail (bypass cache)
  Future<Map<String, dynamic>> refreshProductDetail({
    required int productId,
  }) async {
    _cachedDetails.remove(productId);
    _lastFetch.remove(productId);
    return await getProductDetail(productId: productId);
  }
}
