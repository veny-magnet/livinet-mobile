// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://345a7c068173.ngrok-free.app/api/v1';
  static const String apiServer = 'LIVINET_API_SERVER';
  static const String apiKey = 'LIVINET_API_KEY_12345';
  
  // Login method
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String fcmToken,
    bool rememberMe = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/insert/sign'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'name_server': apiServer,
          'key_server': apiKey,
          'fcm_token': fcmToken,
          'remember_me': rememberMe,
        }),
      );
      
      Map<String, dynamic> responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Save token and user data
        await _saveUserSession(responseData['data']);
        
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
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
  
  // Send email verification
  Future<Map<String, dynamic>> sendEmailVerification({
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send/emailsend'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name_server': apiServer,
          'key_server': apiKey,
          'user_id': userId,
        }),
      );
      
      Map<String, dynamic> responseData = jsonDecode(response.body);
      
      return {
        'success': response.statusCode == 200 && responseData['success'] == true,
        'message': responseData['message'] ?? 'Email verification request processed',
        'data': responseData['data'],
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }
  
  // Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      // Clear local session
      await _clearUserSession();
      
      return {
        'success': true,
        'message': 'Logged out successfully',
        'data': null,
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Logout error: ${e.toString()}',
        'data': null,
      };
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userDataJson = prefs.getString('user_data');
      
      if (userDataJson != null) {
        return jsonDecode(userDataJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Get auth token
  Future<String?> getAuthToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }
  
  // Private method to save user session
  Future<void> _saveUserSession(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Save token
    if (userData['token'] != null) {
      await prefs.setString('auth_token', userData['token']);
    }
    
    // Save user data
    await prefs.setString('user_data', jsonEncode(userData));
    
    // Save login timestamp
    await prefs.setString('login_time', DateTime.now().toIso8601String());
  }
  
  // Private method to clear user session
  Future<void> _clearUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('login_time');
  }
}