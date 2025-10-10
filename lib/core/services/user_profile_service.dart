import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import 'auth_service.dart';

class UserProfileService {
  static const String baseUrl = 'https://276dccd11ccd.ngrok-free.app/api/v1';

  static UserProfileService? _instance;
  UserProfile? _cachedProfile;
  DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  UserProfileService._internal();

  static UserProfileService get instance {
    _instance ??= UserProfileService._internal();
    return _instance!;
  }

  /// Get user profile with caching
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      // Check if we have a valid cached profile
      if (_cachedProfile != null &&
          _lastFetch != null &&
          DateTime.now().difference(_lastFetch!) < _cacheExpiry) {
        return {
          'success': true,
          'data': _cachedProfile,
          'message': 'Profile fetched from cache',
        };
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

        if (responseData['code'] == 200 && responseData['payload'] != null) {
          final profileData = responseData['payload']['profile'];

          // Cache the profile
          _cachedProfile = UserProfile.fromJson(profileData);
          _lastFetch = DateTime.now();

          return {
            'success': true,
            'data': _cachedProfile,
            'message':
                responseData['message'] ?? 'Profile fetched successfully',
          };
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
      print('UserProfileService - Error: $e');
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
      print('UserProfileService - Error (basic info): $e');
      return {
        'success': false,
        'message': 'Error fetching basic profile info: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Clear cached profile data
  void clearCache() {
    _cachedProfile = null;
    _lastFetch = null;
  }

  /// Get cached profile without making API call
  UserProfile? getCachedProfile() {
    if (_cachedProfile != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheExpiry) {
      return _cachedProfile;
    }
    return null;
  }

  /// Force refresh profile data (bypass cache)
  Future<Map<String, dynamic>> refreshProfile(String userId) async {
    clearCache();
    return await getUserProfile(userId);
  }
}
