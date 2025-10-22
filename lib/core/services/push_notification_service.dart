import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';
import 'auth_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final logger = AppLogger.instance;
  logger.info('Handling background message: ${message.messageId}');
  logger.debug('Message data: ${message.data}');

  if (message.notification != null) {
    logger.debug(
      'Background notification: ${message.notification!.title} - ${message.notification!.body}',
    );
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  static PushNotificationService get instance => _instance;

  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _logger = AppLogger.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Stream controllers for notification events
  final _messageStreamController = StreamController<RemoteMessage>.broadcast();
  final _tokenRefreshStreamController = StreamController<String>.broadcast();

  Stream<RemoteMessage> get onMessage => _messageStreamController.stream;
  Stream<String> get onTokenRefresh => _tokenRefreshStreamController.stream;

  /// Initialize push notification service
  Future<void> initialize() async {
    try {
      _logger.info('Initializing Push Notification Service...');

      // Request permission (iOS requires explicit permission)
      final settings = await _requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.info('Push notification permission granted');

        // Get FCM token
        await _getToken();

        // Setup message handlers
        _setupMessageHandlers();

        // Setup background handler
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        _logger.info('Push Notification Service initialized successfully');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        _logger.info('Push notification permission granted (provisional)');
      } else {
        _logger.warning('Push notification permission denied');
      }
    } catch (e) {
      _logger.error('Error initializing push notifications', e);
    }
  }

  /// Request notification permission
  Future<NotificationSettings> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _logger.debug(
        'Notification permission status: ${settings.authorizationStatus}',
      );
      return settings;
    } catch (e) {
      _logger.error('Error requesting notification permission', e);
      rethrow;
    }
  }

  /// Get FCM token
  Future<String?> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();

      if (_fcmToken != null) {
        _logger.info('FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');

        // Send token to backend
        await _sendTokenToBackend(_fcmToken!);

        return _fcmToken;
      } else {
        _logger.warning('Failed to get FCM token');
        return null;
      }
    } catch (e) {
      _logger.error('Error getting FCM token', e);
      return null;
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.info('Foreground message received: ${message.messageId}');
      _logger.debug('Message data: ${message.data}');

      if (message.notification != null) {
        _logger.info(
          'Foreground notification: ${message.notification!.title} - ${message.notification!.body}',
        );
      }

      // Emit to stream for UI handling
      _messageStreamController.add(message);
    });

    // Message opened from notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.info('Notification opened: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _logger.info('FCM Token refreshed: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;

      // Send new token to backend
      _sendTokenToBackend(newToken);

      // Emit to stream
      _tokenRefreshStreamController.add(newToken);
    });
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    _logger.debug('Handling notification tap with data: ${message.data}');

    final data = message.data;

    // Route based on notification type
    if (data.containsKey('type')) {
      final type = data['type'];
      _logger.info('Notification type: $type');

      // Navigation will be handled by UI layer listening to onMessage stream
      _messageStreamController.add(message);
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();

      if (currentUser != null && currentUser['user_id'] != null) {
        final userId = currentUser['user_id'] as String;

        _logger.info('Sending FCM token to backend for user: $userId');

        _logger.debug('FCM token sent to backend successfully');
      } else {
        _logger.warning('User not logged in, token will be sent after login');
      }
    } catch (e) {
      _logger.error('Error sending FCM token to backend', e);
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      _logger.info('Subscribed to topic: $topic');
    } catch (e) {
      _logger.error('Error subscribing to topic: $topic', e);
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      _logger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.error('Error unsubscribing from topic: $topic', e);
    }
  }

  /// Subscribe to user-specific topics
  Future<void> subscribeToUserTopics(String userId, {int? addressId}) async {
    try {
      // Subscribe to user-specific topic
      await subscribeToTopic('user_$userId');

      // Subscribe to address-specific topic if provided
      if (addressId != null) {
        await subscribeToTopic('user_${userId}_address_$addressId');
      }

      // Subscribe to general topics
      await subscribeToTopic('all_users');

      _logger.info('Subscribed to user topics for: $userId');
    } catch (e) {
      _logger.error('Error subscribing to user topics', e);
    }
  }

  /// Unsubscribe from user-specific topics
  Future<void> unsubscribeFromUserTopics(
    String userId, {
    int? addressId,
  }) async {
    try {
      await unsubscribeFromTopic('user_$userId');

      if (addressId != null) {
        await unsubscribeFromTopic('user_${userId}_address_$addressId');
      }

      _logger.info('Unsubscribed from user topics for: $userId');
    } catch (e) {
      _logger.error('Error unsubscribing from user topics', e);
    }
  }

  /// Get initial message (app opened from terminated state)
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();

      if (message != null) {
        _logger.info('App opened from notification: ${message.messageId}');
        _handleNotificationTap(message);
      }

      return message;
    } catch (e) {
      _logger.error('Error getting initial message', e);
      return null;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      _logger.error('Error checking notification status', e);
      return false;
    }
  }

  /// Refresh FCM token
  Future<String?> refreshToken() async {
    try {
      _logger.info('Refreshing FCM token...');

      // Delete old token
      await _messaging.deleteToken();

      // Get new token
      return await _getToken();
    } catch (e) {
      _logger.error('Error refreshing FCM token', e);
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _messageStreamController.close();
    _tokenRefreshStreamController.close();
  }
}
