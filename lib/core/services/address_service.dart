import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';
import 'app_logger.dart';

class UserAddress {
  final String code; // address_code identifier
  final String userCode; // user_code identifier
  final String address;
  final String cityName;
  final int stateId;
  final String stateName;
  final int areaId;
  final String areaName;
  final String postcode;
  final String country;

  UserAddress({
    required this.code,
    required this.userCode,
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
      code: json['code'] ?? '',
      userCode: json['user_code'] ?? '',
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
      'code': code,
      'user_code': userCode,
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
  final _config = AppConfig.instance;
  final _logger = AppLogger.instance;

  static AddressService? _instance;

  AddressService._internal();

  static AddressService get instance {
    _instance ??= AddressService._internal();
    return _instance!;
  }

  /// Get user addresses with authentication - NO CACHE
  Future<Map<String, dynamic>> getUserAddresses(
    String userCode, {
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

      final response = await http.get(
        Uri.parse(
          '${_config.baseUrl}/get/listaddress',
        ).replace(queryParameters: {'code': userCode}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
      );

      _logger.debug('Response status: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['code'] == 200 && responseData['success'] == true) {
          final List<dynamic> addressesData = responseData['data'] ?? [];

          // Parse addresses
          final addresses = addressesData
              .map((json) => UserAddress.fromJson(json))
              .toList();

          return {
            'success': true,
            'data': addresses,
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
      _logger.error('Error getting user addresses', e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Get primary/first address for quick display
  Future<UserAddress?> getPrimaryAddress(String userCode) async {
    try {
      final result = await getUserAddresses(userCode);

      if (result['success'] == true && result['data'] != null) {
        final List<UserAddress> addresses = result['data'];
        return addresses.isNotEmpty ? addresses.first : null;
      }
      return null;
    } catch (e) {
      _logger.error('Error getting primary address', e);
      return null;
    }
  }

  /// Force refresh addresses (bypass cache)
  Future<Map<String, dynamic>> refreshAddresses(String userCode) async {
    return await getUserAddresses(userCode, forceRefresh: true);
  }

  /// Update existing address by address_code
  Future<Map<String, dynamic>> updateAddress({
    required String userCode,
    required String code,
    required String address,
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

      final body = {'user_code': userCode, 'code': code, 'address': address};

      _logger.debug('Updating address with body: $body');

      final response = await http.put(
        Uri.parse('${_config.baseUrl}/update/updateaddress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      _logger.info('Update address response - status: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['code'] == 200 && responseData['success'] == true) {
          // Clear cache to force refresh

          return {
            'success': true,
            'data': responseData['data'],
            'message':
                responseData['message'] ?? 'Address updated successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to update address',
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
      _logger.error('Error updating address', e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Add new address
  Future<Map<String, dynamic>> addAddress({
    required String userCode,
    required String address,
    required int cityId,
    required int stateId,
    required int areaId,
    required String postcode,
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

      final body = {
        'user_code': userCode,
        'address': address,
        'city_id': cityId,
        'state_id': stateId,
        'area_id': areaId,
        'postcode': postcode,
      };

      _logger.debug('Adding address with body: $body');

      final response = await http.post(
        Uri.parse('${_config.baseUrl}/add/address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      _logger.info('Add address response - status: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['code'] == 200 && responseData['success'] == true) {
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ?? 'Address added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add address',
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
      _logger.error('Error adding address', e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Delete address by address_code
  Future<Map<String, dynamic>> deleteAddress({
    required String userCode, // user_code identifier
    required String code, // address_code identifier
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

      final body = {'user_code': userCode, 'code': code};

      _logger.debug('Deleting address with body: $body');

      final response = await http.delete(
        Uri.parse('${_config.baseUrl}/delete/deleteaddress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      _logger.info('Delete address response - status: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['code'] == 200 && responseData['success'] == true) {
          return {
            'success': true,
            'data': responseData['data'],
            'message':
                responseData['message'] ?? 'Address deleted successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to delete address',
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
      _logger.error('Error deleting address', e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }
}
