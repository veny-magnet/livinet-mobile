// lib/services/registration_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class RegistrationService {
  static const String baseUrl = 'https://b3fbc1baea87.ngrok-free.app/api/v1';
  static const String apiServer = 'LIVINET_API_SERVER';
  static const String apiKey = 'LIVINET_API_KEY';

  // Complete registration
  Future<Map<String, dynamic>> register(
    Map<String, dynamic> registrationData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/client/registration'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode(registrationData),
      );

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
          'data': responseData['data'],
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
        'errors': null,
      };
    }
  }

  static int _userCounter = 0;
  String generateUserId() {
    final id = 'CR0050${_userCounter.toString().padLeft(2, '0')}';
    _userCounter++;
    return id;
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
    required String ktpPath,
    required Map<String, dynamic> identityCard,
    String? userId,
    String? fcmToken,
  }) {
    return {
      'user_id': userId ?? generateUserId(),
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
      'status': 'Inactive', // Will be activated after email verification
      'referral_code': referralCode?.trim(),
      'points': 100, // Default points
      'ktp_path': ktpPath,
      'identity_card': identityCard,
      'fcm_token': fcmToken ?? 'TESTTTT-TOKEN',
    };
  }

  // Validate registration data before sending
  Map<String, String> validateRegistrationData(Map<String, dynamic> data) {
    Map<String, String> errors = {};

    // User ID
    if (data['user_id'] == null || data['user_id'].toString().trim().isEmpty) {
      errors['user_id'] = 'User ID is required';
    }

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

    // Identity card data
    if (data['identity_card'] == null) {
      errors['identity_card'] = 'Identity card data is required';
    } else {
      Map<String, dynamic> identityCard = data['identity_card'];
      List<String> requiredFields = [
        'national_id_number',
        'full_name',
        'first_name',
        'last_name',
        'birth_place',
        'birth_date',
        'gender',
        'address',
      ];

      for (String field in requiredFields) {
        if (identityCard[field] == null ||
            identityCard[field].toString().trim().isEmpty) {
          errors['identity_card_$field'] =
              '${field.replaceAll('_', ' ')} is required in identity card';
        }
      }
    }

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
