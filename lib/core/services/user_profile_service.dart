import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import 'auth_service.dart';
import '../config/app_config.dart';
import 'app_logger.dart';
import '../cache/cache_manager.dart';
import '../cache/cache.dart';

class UserProfileService {
  static final _config = AppConfig.instance;
  static String get baseUrl => _config.baseUrl;
  final _logger = AppLogger.instance;
  final _cacheManager = CacheManager.instance;

  static const String CACHE_VERSION = '1.0.0';

  static UserProfileService? _instance;

  UserProfileService._internal();

  static UserProfileService get instance {
    _instance ??= UserProfileService._internal();
    return _instance!;
  }

  /// Get user profile with caching
  Future<Map<String, dynamic>> getUserProfile(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'profile_$userId';

      // Define cache configuration: 20 min fresh, 4 hours stale
      final cacheConfig = CacheConfig(
        maxAge: const Duration(minutes: 20),
        staleAge: const Duration(hours: 4),
        strategy: CacheStrategy.staleWhileRevalidate,
        version: CACHE_VERSION,
      );

      // Check cache first (unless force refresh)
      if (!forceRefresh) {
        final cached = await _cacheManager.get<UserProfile>(
          cacheKey,
          cacheConfig,
          (json) => UserProfile.fromJson(json),
        );

        if (cached != null) {
          return {
            'success': true,
            'data': cached.data,
            'message': 'Profile fetched from cache',
          };
        }
      }

      // Get auth token
      final authService = AuthService();
      final token = await authService.getAuthToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
          'data': null,
        };
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/get/profile',
        ).replace(queryParameters: {'user_id': userId}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        _logger.debug('Response structure: ${responseData.keys}');
        _logger.debug('Full response: $responseData');

        if (responseData['code'] == 200 && responseData['payload'] != null) {
          final profileData = responseData['payload']['profile'];

          _logger.debug('Profile data: $profileData');

          try {
            // Parse and cache the profile
            final profile = UserProfile.fromJson(profileData);

            // Store in cache
            await _cacheManager.set(cacheKey, profile.toJson(), cacheConfig);

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
  Future<Map<String, dynamic>> getBasicProfileInfo(String userId) async {
    try {
      final result = await getUserProfile(userId);

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

      if (currentUser == null || currentUser['user_id'] == null) {
        return {
          'success': false,
          'message': 'User session not found. Please login again.',
          'data': null,
        };
      }

      // Use the user ID from current session
      final userId = currentUser['user_id'] as String;
      return await getUserProfile(userId);
    } catch (e) {
      _logger.error('Error fetching current user profile', e);
      return {
        'success': false,
        'message': 'Error fetching current user profile: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Clear cached profile data
  Future<void> clearCache({String? userId}) async {
    if (userId != null) {
      final cacheKey = 'profile_$userId';
      await _cacheManager.invalidate(cacheKey);
      _logger.debug('Cleared profile cache for user: $userId');
    } else {
      // Clear all profile cache
      await _cacheManager.invalidatePattern(r'^profile_.*');
      _logger.debug('Cleared all profile cache');
    }
  }

  /// Force refresh profile data (bypass cache)
  Future<Map<String, dynamic>> refreshProfile(String userId) async {
    return await getUserProfile(userId, forceRefresh: true);
  }
}
