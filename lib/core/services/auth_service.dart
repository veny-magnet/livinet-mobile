// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../config/secure_storage.dart';
import 'app_logger.dart';
// Cache sync removed - no longer needed without cache system
import 'session_manager.dart';

class AuthService {
  static final _config = AppConfig.instance;
  static final _secureStorage = SecureStorage.instance;
  static final _logger = AppLogger.instance;
  static final _sessionManager = SessionManager.instance;
  static String get apiServer => _config.apiServer;
  static String get apiKey => _config.apiKey;

  // Login method
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String fcmToken,
    bool rememberMe = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_config.baseUrl}/insert/sign'),
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

      // Handle 404 Not Found specifically (invalid email or password)
      if (response.statusCode == 404) {
        _logger.warning('Login failed: 404 Not Found - Invalid credentials');
        return {
          'success': false,
          'message': 'Invalid email or password',
          'data': null,
        };
      }

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Save token and user data
        await _saveUserSession(responseData['data']);

        // Start session timer
        await _sessionManager.startSession();

        // Set user identifier for crash reports
        if (responseData['data']['user_id'] != null) {
          _logger.setUserIdentifier(
            responseData['data']['user_id'].toString(),
            email: responseData['data']['email'],
            name: responseData['data']['name'],
          );
        }

        _logger.info('User logged in successfully with session started');

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
        Uri.parse('${_config.baseUrl}/send/emailsend'),
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
        'success':
            response.statusCode == 200 && responseData['success'] == true,
        'message':
            responseData['message'] ?? 'Email verification request processed',
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
      // Cache sync removed - no longer needed

      // Clear session
      await _sessionManager.logout();

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

  // Check if user is logged in with session validation
  Future<bool> isLoggedIn() async {
    try {
      // Check if basic auth data exists
      final hasAuth = await _secureStorage.isAuthenticated();
      if (!hasAuth) return false;

      // Check session validity
      final isSessionValid = await _sessionManager.isSessionValid();
      if (!isSessionValid) {
        _logger.warning('Session expired, clearing auth data');
        await _clearUserSession();
        return false;
      }

      // Update activity on auth check
      await _sessionManager.updateActivity();

      return true;
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
      return await _secureStorage.getAccessToken();
    } catch (e) {
      return null;
    }
  }

  // Private method to save user session
  Future<void> _saveUserSession(Map<String, dynamic> userData) async {
    _logger.info(
      'Saving user session with data keys: ${userData.keys.toList()}',
    );

    // Save token to secure storage
    if (userData['token'] != null) {
      await _secureStorage.saveAccessToken(userData['token']);
      _logger.info('Access token saved successfully');
    } else {
      _logger.warning('No token found in login response');
    }

    // Save refresh token if available
    if (userData['refresh_token'] != null) {
      await _secureStorage.saveRefreshToken(userData['refresh_token']);
    }

    // Save user ID
    if (userData['user_id'] != null) {
      await _secureStorage.saveUserId(userData['user_id'].toString());
    }

    // Save user email
    if (userData['email'] != null) {
      await _secureStorage.saveUserEmail(userData['email']);
    }

    // Save user name
    if (userData['name'] != null) {
      await _secureStorage.saveUserName(userData['name']);
    }

    // Save full user data to SharedPreferences (non-sensitive data)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
    await prefs.setString('login_time', DateTime.now().toIso8601String());
  }

  // Private method to clear user session
  Future<void> _clearUserSession() async {
    // Clear secure storage
    await _secureStorage.clearAll();

    // Clear SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('login_time');
  }
}
