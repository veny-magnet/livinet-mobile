import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'app_logger.dart';
import '../config/app_config.dart';
import '../cache/cache_manager.dart';
import '../cache/cache.dart';

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
  final _cacheManager = CacheManager.instance;

  static const String CACHE_VERSION = '1.0.0';

  static ProductDetailService? _instance;

  ProductDetailService._internal();

  static ProductDetailService get instance {
    _instance ??= ProductDetailService._internal();
    return _instance!;
  }

  /// Get product detail with authentication
  Future<Map<String, dynamic>> getProductDetail({
    required int productId,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'product_detail_$productId';

      // Define cache configuration: 15 min fresh, 2 hours stale
      final cacheConfig = CacheConfig(
        maxAge: const Duration(minutes: 15),
        staleAge: const Duration(hours: 2),
        strategy: CacheStrategy.staleWhileRevalidate,
        version: CACHE_VERSION,
      );

      // Check cache first unless force refresh
      if (!forceRefresh) {
        final cached = await _cacheManager.get<ProductDetail>(
          cacheKey,
          cacheConfig,
          (json) => ProductDetail.fromJson(json),
        );

        if (cached != null) {
          return {
            'success': true,
            'data': cached.data,
            'message': 'Product detail fetched from cache',
          };
        }
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

      _logger.debug('Product detail response: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['code'] == 200 && responseData['success'] == true) {
          final Map<String, dynamic> productData =
              responseData['data']['product'] ?? {};

          // Parse and cache the product detail
          final productDetail = ProductDetail.fromJson(productData);

          // Store in cache
          await _cacheManager.set(
            cacheKey,
            productDetail.toJson(),
            cacheConfig,
          );

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

  /// Clear cached product details
  Future<void> clearCache({int? productId}) async {
    if (productId != null) {
      final cacheKey = 'product_detail_$productId';
      await _cacheManager.invalidate(cacheKey);
      _logger.debug('Cleared product detail cache for: $productId');
    } else {
      await _cacheManager.invalidatePattern(r'^product_detail_.*');
      _logger.debug('Cleared all product detail cache');
    }
  }

  /// Force refresh product detail (bypass cache)
  Future<Map<String, dynamic>> refreshProductDetail({
    required int productId,
  }) async {
    return await getProductDetail(productId: productId, forceRefresh: true);
  }
}
