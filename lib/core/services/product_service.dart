import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class Product {
  final int pid;
  final int gid;
  final String name;
  final String description;
  final String price;

  Product({
    required this.pid,
    required this.gid,
    required this.name,
    required this.description,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      pid: json['pid'] ?? 0,
      gid: json['gid'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pid': pid,
      'gid': gid,
      'name': name,
      'description': description,
      'price': price,
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

class ProductService {
  static const String baseUrl = 'https://3580dc107926.ngrok-free.app/api/v1';

  static ProductService? _instance;
  Map<String, List<Product>> _cachedProducts = {};
  Map<String, DateTime> _lastFetch = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);

  ProductService._internal();

  static ProductService get instance {
    _instance ??= ProductService._internal();
    return _instance!;
  }

  /// Get products with authentication
  Future<Map<String, dynamic>> getProducts({
    required String userId,
    int? addressId,
  }) async {
    try {
      final cacheKey = 'products_${userId}_${addressId ?? 'no_address'}';
      print('ProductService - Requesting products with key: $cacheKey');

      // Check if we have cached data for this specific key
      if (_cachedProducts.containsKey(cacheKey) &&
          _lastFetch.containsKey(cacheKey) &&
          DateTime.now().difference(_lastFetch[cacheKey]!) < _cacheExpiry) {
        print('ProductService - Returning cached products for key: $cacheKey');
        return {
          'success': true,
          'data': _cachedProducts[cacheKey],
          'message': 'Products fetched from cache',
        };
      }

      print(
        'ProductService - Cache miss, fetching from API for key: $cacheKey',
      );

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
      final Map<String, String> queryParams = {'user_id': userId};

      if (addressId != null) {
        queryParams['address_id'] = addressId.toString();
      }

      final Uri uri = Uri.parse(
        '$baseUrl/get/product',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['code'] == 200 && responseData['success'] == true) {
          final List<dynamic> productsData =
              responseData['data']['product'] ?? [];

          // Cache the products with specific key
          final products = productsData
              .map((json) => Product.fromJson(json))
              .toList();
          _cachedProducts[cacheKey] = products;
          _lastFetch[cacheKey] = DateTime.now();

          print(
            'ProductService - Cached ${products.length} products with key: $cacheKey',
          );

          return {
            'success': true,
            'data': products,
            'message':
                responseData['message'] ?? 'Products fetched successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch products',
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
      print('ProductService - Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Get products for a specific user (uses default/first address)
  Future<Map<String, dynamic>> getProductsForUser(String userId) async {
    return await getProducts(userId: userId);
  }

  /// Get products for a specific address
  Future<Map<String, dynamic>> getProductsForAddress({
    required String userId,
    required int addressId,
  }) async {
    return await getProducts(userId: userId, addressId: addressId);
  }

  /// Clear cached products
  void clearCache({String? userId, int? addressId}) {
    if (userId != null) {
      // Clear cache for specific user and address combination
      if (addressId != null) {
        final cacheKey = 'products_${userId}_$addressId';
        _cachedProducts.remove(cacheKey);
        _lastFetch.remove(cacheKey);
      } else {
        // Clear all cache for this user
        final keysToRemove = _cachedProducts.keys
            .where((key) => key.startsWith('products_$userId'))
            .toList();
        for (final key in keysToRemove) {
          _cachedProducts.remove(key);
          _lastFetch.remove(key);
        }
      }
    } else {
      // Clear all cache
      _cachedProducts.clear();
      _lastFetch.clear();
    }
  }

  /// Get cached products without making API call
  List<Product>? getCachedProducts({required String userId, int? addressId}) {
    final cacheKey = 'products_${userId}_${addressId ?? 'no_address'}';

    if (_cachedProducts.containsKey(cacheKey) &&
        _lastFetch.containsKey(cacheKey) &&
        DateTime.now().difference(_lastFetch[cacheKey]!) < _cacheExpiry) {
      return _cachedProducts[cacheKey];
    }
    return null;
  }

  /// Force refresh products (bypass cache)
  Future<Map<String, dynamic>> refreshProducts({
    required String userId,
    int? addressId,
  }) async {
    final cacheKey = 'products_${userId}_${addressId ?? 'no_address'}';
    _cachedProducts.remove(cacheKey);
    _lastFetch.remove(cacheKey);
    return await getProducts(userId: userId, addressId: addressId);
  }
}
