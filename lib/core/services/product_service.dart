import 'base_api_service.dart';
import 'app_logger.dart';
// Cache imports removed - no longer needed

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
  final _logger = AppLogger.instance;

  static ProductService? _instance;

  ProductService._internal();

  static ProductService get instance {
    _instance ??= ProductService._internal();
    return _instance!;
  }

  /// Get products - NO CACHE, always fetch fresh
  Future<Map<String, dynamic>> getProducts({
    required String userId,
    int? addressId,
    bool forceRefresh = false,
  }) async {
    try {
      _logger.debug('Fetching products from API');

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

        return {
          'success': true,
          'data': products,
          'message': response.message,
          'fromCache': false,
        };
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

      _logger.debug('getAddOnsForSubscription with params: $queryParams');

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
      _logger.error('Error in getAddOnsForSubscription', e);
      return {
        'success': false,
        'message': 'Unexpected error occurred. Please try again.',
        'data': [],
      };
    }
  }

  // Cache methods removed - no longer needed

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
                _logger.debug(
                  'Found matching product by name: ${product.name} (ID: ${product.pid})',
                );
                return product.pid;
              }
            }
          }

          // Strategy 2: Use first available product
          _logger.debug(
            'Using first available product: ${products.first.name} (ID: ${products.first.pid})',
          );
          return products.first.pid;
        }
      }

      // Strategy 3: Parse invoice ID if available
      if (invoiceId != null && invoiceId.isNotEmpty) {
        final parsed = int.tryParse(invoiceId);
        if (parsed != null && parsed > 0) {
          _logger.debug('Using invoice ID as product reference: $parsed');
          return parsed;
        }
      }

      _logger.warning('No suitable product ID found');
      return null;
    } catch (e) {
      _logger.error('Error in getProductIdForBill', e);
      return null;
    }
  }
}
