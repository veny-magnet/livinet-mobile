// lib/services/registration_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'app_logger.dart';

class RegistrationService {
  static final _config = AppConfig.instance;
  static final _logger = AppLogger.instance;
  static String get baseUrl => _config.baseUrl;
  static String get apiServer => _config.apiServer;
  static String get apiKey => _config.apiKey;

  // Complete registration - NO session validation needed for registration
  Future<Map<String, dynamic>> register(
    Map<String, dynamic> registrationData,
  ) async {
    try {
      final fullUrl = '$baseUrl/client/registration';
      _logger.info('Registration URL: $fullUrl');
      _logger.info('Registration data: ${registrationData.keys.toList()}');

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode(registrationData),
      );

      _logger.info('Response status: ${response.statusCode}');
      _logger.info('Response body: ${response.body}');

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _logger.info('Registration successful');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        _logger.error('Registration failed: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
          'data': responseData['data'],
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      _logger.error('Registration network error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
        'errors': null,
      };
    }
  }

  // Build registration data
  Map<String, dynamic> buildRegistrationData({
    required String username,
    required String phone,
    required String email,
    required String password,
    required String address,
    required int cityId,
    required int stateId,
    required int areaId,
    required String postcode,
    String? referralCode,
    String? fcmToken,
  }) {
    return {
      'username': username.trim(),
      'phone': phone.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'address': address.trim(),
      'city_id': cityId,
      'state_id': stateId,
      'area_id': areaId,
      'postcode': postcode.trim(),
      'country': 'Indonesia',
      'referral_code': referralCode?.trim(),
      'fcm_token': fcmToken,
    };
  }

  // Validate registration data before sending
  Map<String, String> validateRegistrationData(Map<String, dynamic> data) {
    Map<String, String> errors = {};

    // Username
    if (data['username'] == null ||
        data['username'].toString().trim().isEmpty) {
      errors['username'] = 'Username is required';
    } else if (data['username'].toString().trim().length < 3) {
      errors['username'] = 'Username must be at least 3 characters';
    }

    // Phone
    String phone = data['phone']?.toString().trim() ?? '';
    if (phone.isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (phone.length < 10 || phone.length > 15) {
      errors['phone'] = 'Phone number must be between 10-15 digits';
    } else if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      errors['phone'] = 'Phone number must contain only digits';
    }

    // Email
    String email = data['email']?.toString().trim() ?? '';
    if (email.isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errors['email'] = 'Please enter a valid email address';
    }

    // Password
    String password = data['password']?.toString() ?? '';
    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length < 8 || password.length > 20) {
      errors['password'] = 'Password must be between 8-20 characters';
    }

    // Address
    if (data['address'] == null ||
        data['address'].toString().trim().length < 5) {
      errors['address'] = 'Address must be at least 5 characters';
    }

    // Location IDs
    if (data['city_id'] == null || data['city_id'] == 0) {
      errors['city_id'] = 'Please select a city';
    }
    if (data['state_id'] == null || data['state_id'] == 0) {
      errors['state_id'] = 'Please select a state/province';
    }
    if (data['area_id'] == null || data['area_id'] == 0) {
      errors['area_id'] = 'Please select an area';
    }

    // Postcode
    if (data['postcode'] == null ||
        data['postcode'].toString().trim().isEmpty) {
      errors['postcode'] = 'Postcode is required';
    }

    // Note: Identity card data validation removed - KTP will be uploaded separately after registration

    return errors;
  }

  // Check if phone number exists
  Future<Map<String, dynamic>> checkPhoneExists(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check/phone'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode({'phone': phone}),
      );

      Map<String, dynamic> responseData = jsonDecode(response.body);

      return {
        'exists': responseData['exists'] ?? false,
        'message': responseData['message'] ?? 'Phone check completed',
      };
    } catch (e) {
      return {'exists': false, 'message': 'Unable to check phone number'};
    }
  }

  // Check if email exists
  Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check/email'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      Map<String, dynamic> responseData = jsonDecode(response.body);

      return {
        'exists': responseData['exists'] ?? false,
        'message': responseData['message'] ?? 'Email check completed',
      };
    } catch (e) {
      return {'exists': false, 'message': 'Unable to check email address'};
    }
  }
}
