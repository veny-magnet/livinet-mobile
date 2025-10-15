import 'base_api_service.dart';

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
  final BaseApiService _apiService = BaseApiService();

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

      // Prepare query parameters
      final Map<String, String> queryParams = {'user_id': userId};
      if (addressId != null) {
        queryParams['address_id'] = addressId.toString();
      }

      // Add additional headers for ngrok
      final additionalHeaders = {'ngrok-skip-browser-warning': 'true'};

      // Use BaseApiService for consistent API calls
      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/product',
        queryParams: queryParams,
        headers: additionalHeaders,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!;
        final List<dynamic> productsData = responseData['product'] ?? [];

        final products = productsData
            .map((json) => Product.fromJson(json))
            .toList();

        _cachedProducts[cacheKey] = products;
        _lastFetch[cacheKey] = DateTime.now();

        return {'success': true, 'data': products, 'message': response.message};
      } else {
        return {'success': false, 'message': response.message, 'data': []};
      }
    } on ApiException catch (e) {
      String errorMessage;
      if (e.statusCode == 500) {
        errorMessage =
            'Server temporarily unavailable. Please try again later.';
      } else if (e.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.message.contains('No internet connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else {
        errorMessage = e.message;
      }

      return {'success': false, 'message': errorMessage, 'data': []};
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error occurred. Please try again.',
        'data': [],
      };
    }
  }

  /// Get products for a specific user (uses default/first address)
  Future<Map<String, dynamic>> getProductsForUser(
    String userId, {
    int? addressId,
    bool forceRefresh = false,
  }) async {
    return await getProducts(userId: userId, addressId: addressId);
  }

  /// Get products for a specific address
  Future<Map<String, dynamic>> getProductsForAddress({
    required String userId,
    required int addressId,
  }) async {
    return await getProducts(userId: userId, addressId: addressId);
  }

  /// Get add-ons available for existing subscription
  Future<Map<String, dynamic>> getAddOnsForSubscription({
    required String userId,
    required String subscriptionId,
    int? addressId,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'user_id': userId,
        'subscription_id': subscriptionId,
      };

      if (addressId != null) {
        queryParams['address_id'] = addressId.toString();
      }

      print(
        'ProductService - getAddOnsForSubscription with params: $queryParams',
      );

      // Add additional headers for ngrok
      final additionalHeaders = {'ngrok-skip-browser-warning': 'true'};

      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/product',
        queryParams: queryParams,
        headers: additionalHeaders,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!;
        final List<dynamic> productsData = responseData['product'] ?? [];

        final products = productsData
            .map((json) => Product.fromJson(json))
            .toList();

        return {'success': true, 'data': products, 'message': response.message};
      } else {
        return {'success': false, 'message': response.message, 'data': []};
      }
    } on ApiException catch (e) {
      String errorMessage;
      if (e.statusCode == 500) {
        errorMessage =
            'Server temporarily unavailable. Please try again later.';
      } else if (e.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.message.contains('No internet connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else {
        errorMessage = e.message;
      }

      return {'success': false, 'message': errorMessage, 'data': []};
    } catch (e) {
      print('ProductService Error - getAddOnsForSubscription: $e');
      return {
        'success': false,
        'message': 'Unexpected error occurred. Please try again.',
        'data': [],
      };
    }
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

  /// Get product ID for bill payment based on bill context
  Future<int?> getProductIdForBill({
    required String userId,
    required int userAddressId,
    String? planName,
    String? invoiceId,
  }) async {
    try {
      // Get products for the user's address
      final result = await getProductsForAddress(
        userId: userId,
        addressId: userAddressId,
      );

      if (result['success'] == true && result['data'] != null) {
        final products = result['data'] as List<Product>;

        if (products.isNotEmpty) {
          // Strategy 1: Match by plan name if provided
          if (planName != null && planName.isNotEmpty) {
            final normalizedPlanName = planName.toLowerCase();

            for (final product in products) {
              final normalizedProductName = product.name.toLowerCase();
              if (normalizedProductName.contains(normalizedPlanName) ||
                  normalizedPlanName.contains(normalizedProductName)) {
                print(
                  'ProductService: Found matching product by name: ${product.name} (ID: ${product.pid})',
                );
                return product.pid;
              }
            }
          }

          // Strategy 2: Use first available product
          print(
            'ProductService: Using first available product: ${products.first.name} (ID: ${products.first.pid})',
          );
          return products.first.pid;
        }
      }

      // Strategy 3: Parse invoice ID if available
      if (invoiceId != null && invoiceId.isNotEmpty) {
        final parsed = int.tryParse(invoiceId);
        if (parsed != null && parsed > 0) {
          print(
            'ProductService: Using invoice ID as product reference: $parsed',
          );
          return parsed;
        }
      }

      print('ProductService: No suitable product ID found');
      return null;
    } catch (e) {
      print('ProductService Error - getProductIdForBill: $e');
      return null;
    }
  }
}
