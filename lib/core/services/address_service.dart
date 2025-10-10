import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class UserAddress {
  final String userId;
  final int addressId;
  final String address;
  final String cityName;
  final int stateId;
  final String stateName;
  final int areaId;
  final String areaName;
  final String postcode;
  final String country;

  UserAddress({
    required this.userId,
    required this.addressId,
    required this.address,
    required this.cityName,
    required this.stateId,
    required this.stateName,
    required this.areaId,
    required this.areaName,
    required this.postcode,
    required this.country,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      userId: json['user_id'] ?? '',
      addressId: json['address_id'] ?? 0,
      address: json['address'] ?? '',
      cityName: json['city_name'] ?? '',
      stateId: json['state_id'] ?? 0,
      stateName: json['state_name'] ?? '',
      areaId: json['area_id'] ?? 0,
      areaName: json['area_name'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? 'ID - Indonesia',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'address_id': addressId,
      'address': address,
      'city_name': cityName,
      'state_id': stateId,
      'state_name': stateName,
      'area_id': areaId,
      'area_name': areaName,
      'postcode': postcode,
      'country': country,
    };
  }

  // Formatted address for display in address selector
  String get formattedAddress {
    return '$address, $areaName, $cityName, $stateName, $postcode';
  }
}

class AddressService {
  static const String baseUrl = 'https://276dccd11ccd.ngrok-free.app/api/v1';

  static AddressService? _instance;
  Map<String, List<UserAddress>> _cachedAddressesByUser = {};
  Map<String, DateTime> _lastFetchByUser = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);

  AddressService._internal();

  static AddressService get instance {
    _instance ??= AddressService._internal();
    return _instance!;
  }

  /// Get user addresses with authentication
  Future<Map<String, dynamic>> getUserAddresses(String userId) async {
    try {
      // Check if we have a valid cached addresses for this specific user
      if (_cachedAddressesByUser.containsKey(userId) &&
          _lastFetchByUser.containsKey(userId) &&
          DateTime.now().difference(_lastFetchByUser[userId]!) < _cacheExpiry) {
        return {
          'success': true,
          'data': _cachedAddressesByUser[userId],
          'message': 'Addresses fetched from cache',
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

      final response = await http.get(
        Uri.parse(
          '$baseUrl/get/listaddress',
        ).replace(queryParameters: {'user_id': userId}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
      );

      print('AddressService - Response status: ${response.statusCode}');
      print('AddressService - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['code'] == 200 && responseData['success'] == true) {
          final List<dynamic> addressesData = responseData['data'] ?? [];

          // Cache the addresses for this specific user
          _cachedAddressesByUser[userId] = addressesData
              .map((json) => UserAddress.fromJson(json))
              .toList();
          _lastFetchByUser[userId] = DateTime.now();

          return {
            'success': true,
            'data': _cachedAddressesByUser[userId],
            'message':
                responseData['message'] ?? 'Addresses fetched successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch addresses',
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
      print('AddressService - Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Get primary/first address for quick display
  Future<UserAddress?> getPrimaryAddress(String userId) async {
    try {
      final result = await getUserAddresses(userId);

      if (result['success'] == true && result['data'] != null) {
        final List<UserAddress> addresses = result['data'];
        return addresses.isNotEmpty ? addresses.first : null;
      }
      return null;
    } catch (e) {
      print('AddressService - Error getting primary address: $e');
      return null;
    }
  }

  /// Clear cached addresses
  void clearCache({String? userId}) {
    if (userId != null) {
      // Clear cache for specific user
      _cachedAddressesByUser.remove(userId);
      _lastFetchByUser.remove(userId);
    } else {
      // Clear all cache
      _cachedAddressesByUser.clear();
      _lastFetchByUser.clear();
    }
  }

  /// Get cached addresses without making API call
  List<UserAddress>? getCachedAddresses(String userId) {
    if (_cachedAddressesByUser.containsKey(userId) &&
        _lastFetchByUser.containsKey(userId) &&
        DateTime.now().difference(_lastFetchByUser[userId]!) < _cacheExpiry) {
      return _cachedAddressesByUser[userId];
    }
    return null;
  }

  /// Force refresh addresses (bypass cache)
  Future<Map<String, dynamic>> refreshAddresses(String userId) async {
    clearCache(userId: userId);
    return await getUserAddresses(userId);
  }
}
