import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PasswordResetService {
  static const String baseUrl = 'https://6e4d717edb7b.ngrok-free.app/api/v1';
  static const String apiServer = 'LIVINET_API_SERVER';
  static const String apiKey = 'LIVINET_API_KEY_12345';
  static PasswordResetService? _instance;

  PasswordResetService._internal();

  static PasswordResetService get instance {
    _instance ??= PasswordResetService._internal();
    return _instance!;
  }

  /// Reset password using phone or email
  Future<Map<String, dynamic>> resetPassword({
    String? phone,
    String? email,
  }) async {
    try {
      // Validation: either phone or email must be provided
      if ((phone == null || phone.isEmpty) &&
          (email == null || email.isEmpty)) {
        return {
          'success': false,
          'message': 'Either phone or email is required',
          'data': null,
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

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'name_server': apiServer,
        'key_server': apiKey,
        'type': 'mobile_app',
      };

      // Add phone or email to request
      if (phone != null && phone.isNotEmpty) {
        requestBody['phone'] = phone;
      }
      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/update/changePassword'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      );

      print('Password Reset Response Status: ${response.statusCode}');
      print('Password Reset Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Password reset successfully',
            'data': responseData['data'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Password reset failed',
            'data': null,
          };
        }
      } else if (response.statusCode == 422) {
        // Validation error
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Validation error',
          'data': null,
          'errors': errorData['data'],
        };
      } else if (response.statusCode == 500) {
        // Server error
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'System error occurred',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to reset password. Server returned ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      print('Password Reset Error: $e');
      return {
        'success': false,
        'message': 'Network error occurred: $e',
        'data': null,
      };
    }
  }

  /// Validate phone number format
  bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;

    // Remove any non-digit characters
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check if length is between 10-15 digits
    return cleanPhone.length >= 10 && cleanPhone.length <= 15;
  }

  /// Validate email format
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    // Basic email validation regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

    return emailRegex.hasMatch(email);
  }

  /// Format phone number for display
  String formatPhoneForDisplay(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.startsWith('0')) {
      return '+62${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('62')) {
      return '+$cleanPhone';
    } else {
      return '+62$cleanPhone';
    }
  }

  /// Clean phone number for API request
  String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
}

/// Data model for password reset response
class PasswordResetResponse {
  final String? code;
  final String? phone;
  final String? email;
  final String? resetPassword;

  PasswordResetResponse({
    this.code,
    this.phone,
    this.email,
    this.resetPassword,
  });

  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetResponse(
      code: json['code'],
      phone: json['phone'],
      email: json['email'],
      resetPassword: json['reset_password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'phone': phone,
      'email': email,
      'reset_password': resetPassword,
    };
  }
}
