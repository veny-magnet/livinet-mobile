import '../services/base_api_service.dart';
import '../models/bill_models.dart';
import '../cache/cache_manager.dart';
import '../cache/cache.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'address_manager.dart';
import '../config/app_config.dart';
import 'app_logger.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  static SubscriptionService get instance => _instance;

  SubscriptionService._internal();

  final BaseApiService _apiService = BaseApiService();
  final AuthService _authService = AuthService();
  final _config = AppConfig.instance;
  final _logger = AppLogger.instance;
  final _cacheManager = CacheManager.instance;

  static const String CACHE_VERSION = '1.0.0';

  Future<Map<String, dynamic>> getUserSubscriptions(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Get selected address from AddressManager
      final selectedAddressId = AddressManager.instance.selectedAddressId;

      final cacheKey =
          'subscriptions_${userId}_${selectedAddressId ?? 'no_address'}';
      final cacheConfig = CacheConfig(
        maxAge: const Duration(minutes: 30),
        staleAge: const Duration(hours: 6),
        strategy: CacheStrategy.staleWhileRevalidate,
        version: CACHE_VERSION,
      );

      if (!forceRefresh) {
        final cached = await _cacheManager.get<Map<String, dynamic>>(
          cacheKey,
          cacheConfig,
          (json) => json,
        );

        if (cached != null && !cached.isExpired(cacheConfig.maxAge)) {
          _logger.debug('Cache HIT: $cacheKey');
          return {
            'success': true,
            'message': 'Subscriptions from cache',
            'data': cached.data,
            'fromCache': true,
          };
        }
      }

      _logger.debug(
        'Cache MISS, fetching subscriptions for userId: $userId, addressId: $selectedAddressId',
      );

      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/subscriptions',
        queryParams: {
          'user_id': userId,
          if (selectedAddressId != null)
            'user_address_id': selectedAddressId.toString(),
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.debug(
        'Raw API response - success: ${response.success}, data: ${response.data}',
      );

      if (response.success && response.data != null) {
        // Update cache
        await _cacheManager.set(cacheKey, response.data!, cacheConfig);

        return {
          'success': true,
          'message': response.message,
          'data': response.data,
          'fromCache': false,
        };
      } else {
        return {'success': false, 'message': response.message, 'data': null};
      }
    } catch (e) {
      _logger.error('Exception occurred while getting subscriptions', e);
      return {
        'success': false,
        'message': 'Failed to get subscriptions: $e',
        'data': null,
      };
    }
  }

  // Convert subscription data to BillHistory format for compatibility
  List<BillHistory> convertSubscriptionsToBills(
    Map<String, dynamic> subscriptionData,
  ) {
    try {
      final List<dynamic> subscriptions =
          subscriptionData['subscriptions'] ?? [];

      return subscriptions.map((sub) {
        return BillHistory(
          amount: sub['monthlyPrice']?.toString() ?? '0',
          paymentStatus: sub['status'] == 'active' ? 'PAID' : 'UNPAID',
          invoiceStatusWhmcs: sub['status'] == 'active' ? 'paid' : 'unpaid',
          paymentDate: sub['status'] == 'active'
              ? DateTime.now().toString()
              : null,
          invoiceId: sub['subsplanID']?.toString() ?? '',
          midtransOrderId: 'SUB-${sub['subsplanID'] ?? 'unknown'}',
          userAddressId: sub['address']?['addressId'],
          createdAt: sub['registrationDate'] ?? DateTime.now().toString(),
        );
      }).toList();
    } catch (e) {
      _logger.error('Error converting subscriptions to bills', e);
      return [];
    }
  }

  Future<Map<String, dynamic>> getActiveSubscription(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      final selectedAddressId = AddressManager.instance.selectedAddressId;

      final cacheKey =
          'active_subscription_${userId}_${selectedAddressId ?? 'no_address'}';
      final cacheConfig = CacheConfig(
        maxAge: const Duration(minutes: 30),
        staleAge: const Duration(hours: 6),
        strategy: CacheStrategy.staleWhileRevalidate,
        version: CACHE_VERSION,
      );

      // Try cache first (unless force refresh)
      if (!forceRefresh) {
        final cached = await _cacheManager.get<Map<String, dynamic>>(
          cacheKey,
          cacheConfig,
          (json) => json,
        );

        if (cached != null && !cached.isExpired(cacheConfig.maxAge)) {
          _logger.debug('Cache HIT: $cacheKey');
          return {'success': true, 'data': cached.data, 'fromCache': true};
        }
      }

      _logger.debug(
        'Cache MISS, getting active subscription for userId: $userId, addressId: $selectedAddressId',
      );

      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/subscriptions',
        queryParams: {
          'user_id': userId,
          if (selectedAddressId != null)
            'user_address_id': selectedAddressId.toString(),
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.debug(
        'Get active subscription response - success: ${response.success}, data: ${response.data}',
      );

      if (response.success && response.data != null) {
        final data = response.data;
        final subscriptions = data?['subscriptions'] as List?;

        if (subscriptions != null && subscriptions.isNotEmpty) {
          final validSubscription = subscriptions.firstWhere(
            (sub) => sub['status'] == 'active' || sub['status'] == 'pending',
            orElse: () => null,
          );

          if (validSubscription != null) {
            _logger.debug(
              'Found subscription with status: ${validSubscription['status']}',
            );

            // Update cache
            await _cacheManager.set(cacheKey, validSubscription, cacheConfig);

            return {
              'success': true,
              'data': validSubscription,
              'fromCache': false,
            };
          } else {
            return {
              'success': false,
              'message': 'No active or pending subscription found',
            };
          }
        } else {
          return {'success': false, 'message': 'No subscriptions found'};
        }
      } else {
        return {'success': false, 'message': response.message};
      }
    } catch (e) {
      _logger.error('Exception in getActiveSubscription', e);
      return {'success': false, 'message': 'Failed to get subscription: $e'};
    }
  }

  Future<Map<String, dynamic>> upgradeSubscription({
    required String userId,
    required String subscriptionId,
    required String targetProductId,
    required String installationDate,
  }) async {
    try {
      _logger.info(
        'Upgrade subscription request - endpoint: ${_config.baseUrl}/update/subscription-upgrade',
      );

      final token = await _authService.getAuthToken();
      if (token == null) {
        _logger.warning('Authentication token not found');
        return {'success': false, 'message': 'Authentication token not found'};
      }

      _logger.debug('Token found: ${token.substring(0, 20)}...');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final requestData = {
        'user_id': userId,
        'subscription_id': subscriptionId,
        'target_product_id': targetProductId,
        'installation_date': installationDate,
      };

      final body = jsonEncode(requestData);

      _logger.debug(
        'Upgrade request - userId: $userId, subscriptionId: $subscriptionId, targetProductId: $targetProductId',
      );

      final response = await http.post(
        Uri.parse('${_config.baseUrl}/update/subscription-upgrade'),
        headers: headers,
        body: body,
      );

      _logger.info(
        'Upgrade subscription response - status: ${response.statusCode}',
      );
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          return {
            'success': true,
            'message':
                jsonResponse['message'] ??
                'Upgrade request submitted successfully',
            'data': jsonResponse['data'],
          };
        } else {
          return {
            'success': false,
            'message':
                jsonResponse['message'] ?? 'Failed to submit upgrade request',
            'error': jsonResponse['error'],
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Subscription or product not found',
        };
      } else if (response.statusCode == 422) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': false,
          'message': 'Validation error',
          'error': jsonResponse['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      _logger.error('Exception in upgradeSubscription', e);
      return {
        'success': false,
        'message': 'Failed to submit upgrade request: $e',
      };
    }
  }

  /// Clear subscription cache
  Future<void> clearCache({String? userId}) async {
    if (userId != null) {
      await _cacheManager.invalidatePattern(
        r'subscriptions_' + userId + r'_.*',
      );
      await _cacheManager.invalidatePattern(
        r'active_subscription_' + userId + r'_.*',
      );
    } else {
      await _cacheManager.invalidatePattern(r'subscriptions_.*');
      await _cacheManager.invalidatePattern(r'active_subscription_.*');
    }
    _logger.debug('Subscription cache cleared for user: ${userId ?? "all"}');
  }

  /// Force refresh subscriptions (bypass cache)
  Future<Map<String, dynamic>> refreshSubscriptions(String userId) async {
    await clearCache(userId: userId);
    return await getUserSubscriptions(userId, forceRefresh: true);
  }

  /// Force refresh active subscription (bypass cache)
  Future<Map<String, dynamic>> refreshActiveSubscription(String userId) async {
    await clearCache(userId: userId);
    return await getActiveSubscription(userId, forceRefresh: true);
  }
}
