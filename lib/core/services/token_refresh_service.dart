import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/secure_storage.dart';

/// Token refresh service
/// Handles automatic token refresh before expiry
class TokenRefreshService {
  static final TokenRefreshService _instance = TokenRefreshService._internal();
  static TokenRefreshService get instance => _instance;
  TokenRefreshService._internal();

  final _config = AppConfig.instance;
  final _secureStorage = SecureStorage.instance;

  Timer? _refreshTimer;
  bool _isRefreshing = false;

  // Token expiry configuration
  static const int tokenExpiryMinutes = 60; // Default: 1 hour
  static const int refreshBeforeExpiryMinutes =
      5; // Refresh 5 minutes before expiry

  /// Initialize token refresh monitoring
  Future<void> initialize() async {
    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      _scheduleTokenRefresh();
    }
  }

  /// Schedule automatic token refresh
  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();

    // Calculate when to refresh (5 minutes before expiry)
    final refreshInterval = Duration(
      minutes: tokenExpiryMinutes - refreshBeforeExpiryMinutes,
    );

    _refreshTimer = Timer.periodic(refreshInterval, (timer) async {
      await refreshToken();
    });
  }

  /// Refresh access token
  Future<Map<String, dynamic>> refreshToken() async {
    if (_isRefreshing) {
      return {'success': false, 'message': 'Token refresh already in progress'};
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        // No refresh token, need to re-login
        await _handleRefreshFailure();
        return {
          'success': false,
          'message': 'No refresh token available. Please login again.',
          'require_login': true,
        };
      }

      final response = await http
          .post(
            Uri.parse('${_config.baseUrl}/auth/refresh'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $refreshToken',
            },
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Token refresh timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final newAccessToken = data['data']['access_token'];
          final newRefreshToken = data['data']['refresh_token'];

          // Save new tokens
          await _secureStorage.saveAccessToken(newAccessToken);
          if (newRefreshToken != null) {
            await _secureStorage.saveRefreshToken(newRefreshToken);
          }

          _scheduleTokenRefresh();

          return {'success': true, 'message': 'Token refreshed successfully'};
        }
      }

      // Refresh failed
      await _handleRefreshFailure();
      return {
        'success': false,
        'message': 'Token refresh failed. Please login again.',
        'require_login': true,
      };
    } catch (e) {
      await _handleRefreshFailure();
      return {
        'success': false,
        'message': 'Token refresh error: ${e.toString()}',
        'require_login': true,
      };
    } finally {
      _isRefreshing = false;
    }
  }

  /// Handle refresh failure - clear tokens and stop timer
  Future<void> _handleRefreshFailure() async {
    _refreshTimer?.cancel();
    await _secureStorage.clearTokens();
  }

  /// Stop token refresh monitoring
  void stop() {
    _refreshTimer?.cancel();
  }

  /// Check if token is about to expire
  Future<bool> isTokenExpiringSoon() async {
    return false;
  }

  /// Dispose resources
  void dispose() {
    _refreshTimer?.cancel();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
