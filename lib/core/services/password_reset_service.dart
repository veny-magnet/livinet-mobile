import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';
import 'app_logger.dart';

class PasswordResetService {
  static final _config = AppConfig.instance;
  static String get baseUrl => _config.baseUrl;
  static String get apiServer => _config.apiServer;
  static String get apiKey => _config.apiKey;
  static PasswordResetService? _instance;
  final _logger = AppLogger.instance;

  PasswordResetService._internal();

  static PasswordResetService get instance {
    _instance ??= PasswordResetService._internal();
    return _instance!;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    String? email,
  }) async {
    try {
      _logger.info('Starting change password request');

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        _logger.warning('No auth token found');
        return {
          'success': false,
          'message': 'Authentication token not found',
          'data': null,
        };
      }

      // Get user info
      final userInfo = await authService.getCurrentUser();
      if (email == null || email.isEmpty) {
        email = userInfo?['user_email'];
      }

      final phone = userInfo?['phone'];

      if ((email == null || email.isEmpty) &&
          (phone == null || phone.isEmpty)) {
        _logger.warning('No email or phone found');
        return {
          'success': false,
          'message': 'User email or phone not found',
          'data': null,
        };
      }

      _logger.debug('Email: $email, Phone: $phone');

      // Prepare request body - Backend will generate random password
      final Map<String, dynamic> requestBody = {
        'name_server': apiServer,
        'key_server': apiKey,
        'type': 'reset', // Backend uses 'reset' type to generate new password
      };

      // Add email or phone (backend checks both)
      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        requestBody['phone'] = phone;
      }

      _logger.debug('Request URL: $baseUrl/post/changePassword');
      _logger.debug('Request body: ${jsonEncode(requestBody)}');

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/post/changePassword'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'name_server': apiServer,
          'key_server': apiKey,
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      );

      _logger.info('Response Status: ${response.statusCode}');
      _logger.debug('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          // Extract new password from response
          final newPassword = responseData['data']?['reset_password'];

          return {
            'success': true,
            'message':
                responseData['message'] ??
                'Password has been reset. New password sent to your email.',
            'data': responseData['data'],
            'new_password': newPassword, // For display if needed
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Password reset failed',
            'data': null,
          };
        }
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Validation error',
          'data': null,
          'errors': errorData['data'],
        };
      } else if (response.statusCode == 500) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        final whmcsError = errorData['data']?['whmcs'];
        return {
          'success': false,
          'message':
              whmcsError ?? errorData['message'] ?? 'System error occurred',
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
    } catch (e, stackTrace) {
      _logger.error('Error in changePassword', e, stackTrace);
      return {
        'success': false,
        'message': 'Network error occurred: $e',
        'data': null,
      };
    }
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
        'type': 'reset',
        'email': email,
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
        Uri.parse('$baseUrl/post/changePassword'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      );

      _logger.info('Password Reset Response Status: ${response.statusCode}');
      _logger.debug('Password Reset Response Body: ${response.body}');

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
      _logger.error('Error in resetPassword', e);
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
