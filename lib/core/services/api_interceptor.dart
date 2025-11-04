import 'package:http/http.dart' as http;
import 'dart:convert';
import 'session_manager.dart';
import 'auth_service.dart';
import 'app_logger.dart';

class ApiInterceptor {
  static final SessionManager _sessionManager = SessionManager.instance;
  static final AuthService _authService = AuthService();
  static final AppLogger _logger = AppLogger.instance;

  /// Make authenticated request with session check
  static Future<http.Response> request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
    bool requireAuth = true,
  }) async {
    try {
      // Check authentication and session for protected routes
      if (requireAuth) {
        final isAuthenticated = await _authService.isLoggedIn();
        if (!isAuthenticated) {
          throw ApiException('Session expired. Please login again.', 401);
        }
      }

      // Prepare headers
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Accept': 'application/json',
        ...?headers,
      };

      if (requireAuth) {
        final token = await _authService.getAuthToken();
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
        }
      }

      // Make request based on method
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: body is String ? body : jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: body is String ? body : jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method', 400);
      }

      // Update activity on successful API call
      if (requireAuth && response.statusCode < 400) {
        await _sessionManager.updateActivity();
      }

      // Handle 401 responses (token expired from server)
      if (response.statusCode == 401) {
        _logger.warning('Received 401 from server, forcing logout');
        await _authService.logout();
        throw ApiException('Session expired. Please login again.', 401);
      }

      return response;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      _logger.error('API request error', e);
      throw ApiException('Network error: ${e.toString()}', 500);
    }
  }

  /// GET request wrapper
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return request('GET', uri, headers: headers, requireAuth: requireAuth);
  }

  /// POST request wrapper
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
    bool requireAuth = true,
  }) async {
    return request(
      'POST',
      uri,
      headers: headers,
      body: body,
      requireAuth: requireAuth,
    );
  }

  /// PUT request wrapper
  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
    bool requireAuth = true,
  }) async {
    return request(
      'PUT',
      uri,
      headers: headers,
      body: body,
      requireAuth: requireAuth,
    );
  }

  /// DELETE request wrapper
  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return request('DELETE', uri, headers: headers, requireAuth: requireAuth);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
