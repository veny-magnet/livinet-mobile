import 'dart:convert';
import '../models/user_profile.dart';
import 'auth_service.dart';
import '../config/app_config.dart';
import 'app_logger.dart';
import 'api_interceptor.dart';

class UserProfileService {
  static final _config = AppConfig.instance;
  static String get baseUrl => _config.baseUrl;
  final _logger = AppLogger.instance;

  static UserProfileService? _instance;

  UserProfileService._internal();

  static UserProfileService get instance {
    _instance ??= UserProfileService._internal();
    return _instance!;
  }

  /// Get user profile - always fetch fresh from API
  Future<Map<String, dynamic>> getUserProfile(
    String code, {
    bool forceRefresh = false,
  }) async {
    try {
      // Make API request with session validation - NO CACHE
      final response = await ApiInterceptor.get(
        Uri.parse(
          '$baseUrl/get/profile',
        ).replace(queryParameters: {'code': code}),
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        _logger.debug('Response structure: ${responseData.keys}');
        _logger.debug('Full response: $responseData');

        if (responseData['code'] == 200 && responseData['payload'] != null) {
          final profileData = responseData['payload']['profile'];

          _logger.debug('Profile data: $profileData');

          try {
            // Parse the profile - NO CACHE
            final profile = UserProfile.fromJson(profileData);

            return {
              'success': true,
              'data': profile,
              'message':
                  responseData['message'] ?? 'Profile fetched successfully',
            };
          } catch (e) {
            _logger.error('Error parsing profile', e);
            return {
              'success': false,
              'message': 'Error parsing profile data: $e',
              'data': null,
            };
          }
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch profile',
            'data': null,
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      _logger.error('Error getting user profile', e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Get basic profile info for home screen (points, username, user ID)
  Future<Map<String, dynamic>> getBasicProfileInfo(String code) async {
    try {
      final result = await getUserProfile(code);

      if (result['success'] == true && result['data'] != null) {
        final UserProfile profile = result['data'];

        return {
          'success': true,
          'data': {
            'points': profile.points,
            'username': profile.username,
            'userId': profile.userId,
          },
          'message': 'Basic profile info fetched successfully',
        };
      } else {
        return result;
      }
    } catch (e) {
      _logger.error('Error fetching basic profile info', e);
      return {
        'success': false,
        'message': 'Error fetching basic profile info: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Get current user profile using auth token
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      // Get auth token and current user data
      final authService = AuthService();
      final token = await authService.getAuthToken();
      final currentUser = await authService.getCurrentUser();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
          'data': null,
        };
      }

      if (currentUser == null || currentUser['code'] == null) {
        return {
          'success': false,
          'message': 'User session not found. Please login again.',
          'data': null,
        };
      }

      // Use the code from current session
      final code = currentUser['code'] as String;
      return await getUserProfile(code);
    } catch (e) {
      _logger.error('Error fetching current user profile', e);
      return {
        'success': false,
        'message': 'Error fetching current user profile: ${e.toString()}',
        'data': null,
      };
    }
  }

  // Cache methods removed - no longer needed without cache system
}
