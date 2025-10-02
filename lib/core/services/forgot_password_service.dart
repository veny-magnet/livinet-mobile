import 'dart:convert';
import 'package:http/http.dart' as http;

class ForgotPasswordService {
  static const String baseUrl = 'https://345a7c068173.ngrok-free.app/api/v1';
  
  /// Send OTP to email
  Future<Map<String, dynamic>> sendOTP({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password/send-otp'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
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
          'message': responseData['message'] ?? 'Failed to send OTP',
          'data': null,
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }
  
  /// Verify OTP code
  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
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
          'message': responseData['message'] ?? 'OTP verification failed',
          'data': null,
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }
  
  /// Reset password with OTP
  Future<Map<String, dynamic>> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
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
          'message': responseData['message'] ?? 'Password reset failed',
          'data': null,
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }
  
  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  /// Validate OTP format (5 digits)
  bool isValidOTP(String otp) {
    return RegExp(r'^\d{5}$').hasMatch(otp);
  }
  
  /// Validate password strength
  Map<String, dynamic> validatePassword(String password) {
    Map<String, String> errors = {};
    
    if (password.length < 8) {
      errors['length'] = 'Password must be at least 8 characters';
    }
    
    if (password.length > 50) {
      errors['max_length'] = 'Password must not exceed 50 characters';
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }
}
