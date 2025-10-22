// lib/core/services/realtime/user_profile_update_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../user_profile_service.dart';
import '../app_logger.dart';
import '../../cache/cache_manager.dart';

/// Service untuk menangani real-time user profile updates via push notifications
///
/// Features:
/// - Subscribe to user-specific profile update topics
/// - Auto-invalidate cache when profile data changes
/// - Handle profile edits, point updates, verification status changes
/// - Broadcast profile updates to UI via streams
class UserProfileUpdateService {
  static final UserProfileUpdateService _instance =
      UserProfileUpdateService._internal();
  static UserProfileUpdateService get instance => _instance;
  UserProfileUpdateService._internal();

  final _logger = AppLogger.instance;
  final _messaging = FirebaseMessaging.instance;
  final _cacheManager = CacheManager.instance;

  // Stream controller for broadcasting profile updates to UI
  final _profileUpdateController =
      StreamController<ProfileUpdateEvent>.broadcast();
  Stream<ProfileUpdateEvent> get onProfileUpdate =>
      _profileUpdateController.stream;

  bool _isInitialized = false;
  String? _currentUserId;

  /// Initialize profile update service for a specific user
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) {
      _logger.info(
        'UserProfileUpdateService already initialized for user: $userId',
      );
      return;
    }

    try {
      // Unsubscribe from previous user topics if switching users
      if (_currentUserId != null && _currentUserId != userId) {
        await unsubscribe(_currentUserId!);
      }

      // Subscribe to profile updates topic for this user
      await _messaging.subscribeToTopic('profile_updates_$userId');
      _logger.info('Subscribed to profile_updates_$userId');

      // Setup message handlers
      _setupMessageHandlers();

      _currentUserId = userId;
      _isInitialized = true;

      _logger.info('UserProfileUpdateService initialized for user: $userId');
    } catch (e) {
      _logger.error('Failed to initialize UserProfileUpdateService', e);
      rethrow;
    }
  }

  /// Setup Firebase message handlers for different app states
  void _setupMessageHandlers() {
    // Foreground messages (app is open and visible)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.info('Received foreground profile update: ${message.messageId}');
      _handleProfileUpdate(message, isBackground: false);
    });

    // Background messages (app is minimized but running)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.info(
        'App opened from background profile notification: ${message.messageId}',
      );
      _handleProfileUpdate(message, isBackground: true);
    });
  }

  /// Handle incoming profile update notifications
  void _handleProfileUpdate(
    RemoteMessage message, {
    bool isBackground = false,
  }) {
    try {
      final data = message.data;
      final notificationType = data['type'] as String?;

      // Only process profile-related notifications
      if (notificationType == null ||
          !notificationType.startsWith('profile_')) {
        return;
      }

      final userId = data['user_id'] as String?;
      final updateField = data['update_field'] as String?;
      final newValue = data['new_value'] as String?;
      final points = data['points'] as String?;

      _logger.info(
        'Processing profile update: type=$notificationType, '
        'userId=$userId, field=$updateField, value=$newValue',
      );

      if (userId == null) {
        _logger.warning('Profile update missing user_id');
        return;
      }

      // Invalidate relevant caches
      _invalidateProfileCache(
        userId: userId,
        notificationType: notificationType,
      );

      // Broadcast event to UI
      final event = ProfileUpdateEvent(
        type: _mapNotificationType(notificationType),
        userId: userId,
        updateField: updateField,
        newValue: newValue,
        points: points != null ? int.tryParse(points) : null,
        message: message.notification?.body,
        isBackground: isBackground,
        timestamp: DateTime.now(),
      );

      _profileUpdateController.add(event);

      _logger.info('Profile update event broadcasted: ${event.type}');
    } catch (e) {
      _logger.error('Error handling profile update', e);
    }
  }

  /// Invalidate profile cache based on notification type
  void _invalidateProfileCache({
    required String userId,
    required String notificationType,
  }) {
    try {
      switch (notificationType) {
        case 'profile_edited':
        case 'profile_points_updated':
        case 'profile_verified':
        case 'profile_photo_updated':
        case 'profile_email_verified':
        case 'profile_phone_verified':
          // Invalidate user profile cache
          _cacheManager.invalidate('profile_$userId');
          _logger.info('Invalidated profile cache for user: $userId');
          break;

        case 'profile_password_changed':
          // Password changed - no cache to invalidate (not stored)
          _logger.info(
            'Password changed notification (no cache invalidation needed)',
          );
          break;

        default:
          // Unknown type, invalidate all to be safe
          _cacheManager.invalidate('profile_$userId');
          _logger.warning(
            'Unknown profile notification type: $notificationType',
          );
      }

      // Prefetch new data in background
      _prefetchProfileData(userId);
    } catch (e) {
      _logger.error('Error invalidating profile cache', e);
    }
  }

  /// Prefetch updated profile data in background
  Future<void> _prefetchProfileData(String userId) async {
    try {
      // Prefetch fresh profile data
      await UserProfileService.instance.getUserProfile(
        userId,
        forceRefresh: true,
      );
      _logger.info('Prefetched profile for user: $userId');
    } catch (e) {
      _logger.error('Failed to prefetch profile data', e);
      // Non-critical, don't throw
    }
  }

  /// Map notification type string to enum
  ProfileUpdateType _mapNotificationType(String type) {
    switch (type) {
      case 'profile_edited':
        return ProfileUpdateType.profileEdited;
      case 'profile_points_updated':
        return ProfileUpdateType.pointsUpdated;
      case 'profile_verified':
        return ProfileUpdateType.verified;
      case 'profile_photo_updated':
        return ProfileUpdateType.photoUpdated;
      case 'profile_email_verified':
        return ProfileUpdateType.emailVerified;
      case 'profile_phone_verified':
        return ProfileUpdateType.phoneVerified;
      case 'profile_password_changed':
        return ProfileUpdateType.passwordChanged;
      default:
        return ProfileUpdateType.unknown;
    }
  }

  /// Unsubscribe from all profile update topics
  Future<void> unsubscribe(String userId) async {
    try {
      await _messaging.unsubscribeFromTopic('profile_updates_$userId');
      _logger.info('Unsubscribed from profile_updates_$userId');

      _isInitialized = false;
      _currentUserId = null;
    } catch (e) {
      _logger.error('Failed to unsubscribe from profile updates', e);
    }
  }

  /// Dispose resources
  void dispose() {
    _profileUpdateController.close();
    _isInitialized = false;
    _currentUserId = null;
  }
}

/// Profile update event types
enum ProfileUpdateType {
  profileEdited, // Profile information edited (name, address, etc)
  pointsUpdated, // User points balance updated
  verified, // Account verified
  photoUpdated, // Profile photo changed
  emailVerified, // Email address verified
  phoneVerified, // Phone number verified
  passwordChanged, // Password changed
  unknown, // Unknown type
}

/// Profile update event data
class ProfileUpdateEvent {
  final ProfileUpdateType type;
  final String userId;
  final String? updateField; // Which field was updated
  final String? newValue; // New value of the field
  final int? points; // New points balance (if points_updated)
  final String? message;
  final bool isBackground;
  final DateTime timestamp;

  ProfileUpdateEvent({
    required this.type,
    required this.userId,
    this.updateField,
    this.newValue,
    this.points,
    this.message,
    required this.isBackground,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'ProfileUpdateEvent(type: $type, userId: $userId, '
        'field: $updateField, value: $newValue, points: $points)';
  }
}
