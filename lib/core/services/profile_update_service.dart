import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'app_logger.dart';
import '../config/app_config.dart';

class ProfileUpdateService {
  static final _config = AppConfig.instance;
  static final _logger = AppLogger.instance;
  static String get baseUrl => _config.baseUrl;
  static ProfileUpdateService? _instance;

  ProfileUpdateService._internal();

  static ProfileUpdateService get instance {
    _instance ??= ProfileUpdateService._internal();
    return _instance!;
  }

  /// Update phone number
  Future<Map<String, dynamic>> updatePhone({
    required String userId,
    required String oldPhone,
    required String newPhone,
  }) async {
    try {
      _logger.info('Starting phone update for user: $userId');
      _logger.debug('Phone change: $oldPhone -> $newPhone');

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();

      if (token == null) {
        _logger.warning('Phone update failed: No auth token found');
        return {
          'success': false,
          'message': 'Authentication token not found',
          'data': null,
        };
      }

      // Format phone numbers to database format (+62.xxx-xxxx-xxxx)
      final formattedOldPhone = formatPhoneForDatabase(oldPhone);
      final formattedNewPhone = formatPhoneForDatabase(newPhone);

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'user_id': userId,
        'oldphone': formattedOldPhone,
        'phone': formattedNewPhone,
      };

      _logger.debug('Phone update request to: $baseUrl/update/phoneupdate');
      _logger.debug('Request body: ${jsonEncode(requestBody)}');

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/update/phoneupdate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      );

      _logger.debug('Phone update response: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true || responseData['code'] == 200) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Phone updated successfully',
            'data': responseData['payload'] ?? responseData['data'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Phone update failed',
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
              'Failed to update phone. Server returned ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e, stackTrace) {
      _logger.error('Phone update failed', e, stackTrace);
      return {
        'success': false,
        'message': 'Network error occurred: $e',
        'data': null,
      };
    }
  }

  /// Update email
  Future<Map<String, dynamic>> updateEmail({
    required String userId,
    required String newEmail,
  }) async {
    try {
      _logger.info('Starting email update for user: $userId');
      _logger.debug('New email: $newEmail');

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();

      if (token == null) {
        _logger.warning('Email update failed: No auth token found');
        return {
          'success': false,
          'message': 'Authentication token not found',
          'data': null,
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'user_id': userId,
        'email': newEmail,
      };

      _logger.debug('Email update request to: $baseUrl/update/emailupdate');
      _logger.debug('Request body: ${jsonEncode(requestBody)}');

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/update/emailupdate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      );

      _logger.debug('Email update response: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true || responseData['code'] == 200) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Email updated successfully',
            'data': responseData['payload'] ?? responseData['data'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Email update failed',
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
              'Failed to update email. Server returned ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e, stackTrace) {
      _logger.error('Email update failed', e, stackTrace);
      return {
        'success': false,
        'message': 'Network error occurred: $e',
        'data': null,
      };
    }
  }

  /// Change password (manual password change - different from reset)
  Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      _logger.info('Starting password change for user: $userId');

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();

      if (token == null) {
        _logger.warning('Password change failed: No auth token found');
        return {
          'success': false,
          'message': 'Authentication token not found',
          'data': null,
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'code': userId,
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      };

      _logger.debug(
        'Password change request to: $baseUrl/update/changePassword',
      );
      _logger.debug('Request with password fields (values hidden)');

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

      _logger.debug('Password change response: ${response.statusCode}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true || responseData['code'] == 200) {
          return {
            'success': true,
            'message':
                responseData['message'] ?? 'Password changed successfully',
            'data': responseData['payload'] ?? responseData['data'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Password change failed',
            'data': null,
          };
        }
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Old password is incorrect',
          'data': null,
        };
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
              'Failed to change password. Server returned ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e, stackTrace) {
      _logger.error('Password change failed', e, stackTrace);
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
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleanPhone.length >= 10 && cleanPhone.length <= 15;
  }

  /// Validate email format
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(email);
  }

  /// Format phone number for database (e.g., +62.876-4331-9477)
  String formatPhoneForDatabase(String phone) {
    // Remove all non-digit characters
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    String phoneWithCountryCode;

    // Add country code if not present
    if (cleanPhone.startsWith('0')) {
      phoneWithCountryCode = '62${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('62')) {
      phoneWithCountryCode = cleanPhone;
    } else {
      phoneWithCountryCode = '62$cleanPhone';
    }

    // Format: +62.xxx-xxxx-xxxx
    if (phoneWithCountryCode.length >= 11) {
      final countryCode = phoneWithCountryCode.substring(0, 2); // 62
      final part1 = phoneWithCountryCode.substring(2, 5); // 3 digits
      final part2 = phoneWithCountryCode.substring(5, 9); // 4 digits
      final part3 = phoneWithCountryCode.substring(9); // remaining digits

      return '+$countryCode.$part1-$part2-$part3';
    }

    // If format doesn't match expected length, return with + prefix
    return '+$phoneWithCountryCode';
  }

  /// Format phone number for display
  String formatPhoneForDisplay(String phone) {
    // If already formatted, return as is
    if (phone.contains('.') || phone.contains('-')) {
      return phone;
    }

    return formatPhoneForDatabase(phone);
  }

  /// Clean phone number for API request (remove all formatting)
  String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
}
