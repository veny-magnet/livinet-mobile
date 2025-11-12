import '../services/base_api_service.dart';
import '../models/bill_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
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

  /// Get user subscriptions - NO CACHE, always fresh from server
  /// If [addressId] is provided: returns per-address subscriptions
  /// If [addressId] is null: returns global user subscriptions (all addresses)
  Future<Map<String, dynamic>> getUserSubscriptions(
    String userId, {
    int? addressId, // Optional: if provided, get per-address subscriptions
    bool forceRefresh = false, // Keep for backward compatibility
  }) async {
    try {
      // Only use provided addressId - NO fallback to AddressManager
      // This ensures independent calls: with addressId = per-address, without = global
      _logger.debug(
        'Fetching subscriptions for userId: $userId, addressId: $addressId (global: ${addressId == null})',
      );

      // Make API request - NO CACHE, always fresh
      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/subscriptions',
        queryParams: {
          'user_id': userId,
          if (addressId != null) 'address_id': addressId.toString(),
          // If addressId is null, parameter is NOT included (global query)
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _logger.debug(
        'Raw API response - success: ${response.success}, data: ${response.data}',
      );

      if (response.success && response.data != null) {
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
      if (e.toString().contains('404')) {
        _logger.debug('No subscriptions found (404) - this is normal');
        return {
          'success': true,
          'message': 'No subscriptions found',
          'data': {'subscriptions': []},
        };
      }

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

  /// Get active subscription - NO CACHE, always fresh from server
  Future<Map<String, dynamic>> getActiveSubscription(
    String userId, {
    int? addressId,
    bool forceRefresh = false, // Keep for backward compatibility
  }) async {
    try {
      // Only use provided addressId - NO fallback
      _logger.debug(
        'Getting active subscription for userId: $userId, addressId: $addressId (global: ${addressId == null})',
      );

      // Make API request - NO CACHE, always fresh
      final response = await _apiService.get<Map<String, dynamic>>(
        '/get/subscriptions',
        queryParams: {
          'user_id': userId,
          if (addressId != null) 'address_id': addressId.toString(),
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

  /// Refresh subscriptions (no-op since we removed cache)
  Future<Map<String, dynamic>> refreshSubscriptions(String userId) async {
    return await getUserSubscriptions(userId, forceRefresh: true);
  }

  /// Refresh active subscription (no-op since we removed cache)
  Future<Map<String, dynamic>> refreshActiveSubscription(String userId) async {
    return await getActiveSubscription(userId, forceRefresh: true);
  }
}
