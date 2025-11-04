import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

class FcmService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final _logger = AppLogger.instance;

  /// Initialize FCM and request permission
  static Future<void> initialize() async {
    try {
      // Request permission for notifications with proper settings
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
            criticalAlert: false,
            carPlay: false,
            announcement: false,
          );

      _logger.info('FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _logger.warning('FCM notifications are denied by user');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        _logger.info('FCM notifications are authorized');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        _logger.info('FCM notifications are provisionally authorized');
      }

      // Get initial FCM token
      await getFcmToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _saveFcmToken(token);
      });
    } catch (e) {
      _logger.error('Error initializing FCM', e);
    }
  }

  /// Get FCM token from device
  static Future<String?> getFcmToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        await _saveFcmToken(token);
      }

      return token;
    } catch (e) {
      _logger.error('Error getting FCM token', e);
      return null;
    }
  }

  /// Save FCM token to local storage
  static Future<void> _saveFcmToken(String token) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      _logger.debug('FCM Token saved: ${token.substring(0, 20)}...');
    } catch (e) {
      _logger.error('Error saving FCM token', e);
    }
  }

  /// Get saved FCM token from local storage
  static Future<String?> getSavedFcmToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      _logger.error('Error getting saved FCM token', e);
      return null;
    }
  }

  /// Get device FCM token for registration/login with permission check
  static Future<String> getTokenForRegistration() async {
    try {
      // Check current permission status first
      NotificationSettings settings = await _firebaseMessaging
          .getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        // Re-request permission if denied or not determined
        await initialize();

        // Check again after re-initialization
        settings = await _firebaseMessaging.getNotificationSettings();

        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          throw Exception(
            'Notification permission is required for registration. Please go to app settings and enable notifications.',
          );
        }
      }

      // Try multiple times to get token with delay
      for (int attempt = 1; attempt <= 5; attempt++) {
        _logger.debug('Attempting to get FCM token, attempt $attempt/5');

        String? token = await _firebaseMessaging.getToken();

        if (token != null && token.isNotEmpty) {
          await _saveFcmToken(token);
          _logger.info(
            'FCM Token obtained successfully: ${token.substring(0, 20)}...',
          );
          return token;
        }

        // Wait before retry, increasing delay each time
        if (attempt < 5) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }

      // Try to get saved token as fallback
      String? savedToken = await getSavedFcmToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        _logger.warning('Using saved FCM token as fallback');
        return savedToken;
      }

      // If all fails, throw error - FCM token is required for registration
      throw Exception(
        'Failed to obtain FCM token after multiple attempts. Please check your internet connection and try again.',
      );
    } catch (e) {
      _logger.error('Critical error getting FCM token for registration', e);
      throw Exception('Unable to get notification token: ${e.toString()}');
    }
  }

  /// Handle foreground messages
  static void handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.info(
        'Received foreground message: ${message.notification?.title}',
      );
      // Handle foreground notification here
    });
  }

  /// Handle background messages
  static void handleBackgroundMessages() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    _logger.info('Received background message: ${message.notification?.title}');
    // Handle background notification here
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _logger.info('Subscribed to FCM topic: $topic');
    } catch (e) {
      _logger.error('Error subscribing to topic', e);
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _logger.info('Unsubscribed from FCM topic: $topic');
    } catch (e) {
      _logger.error('Error unsubscribing from topic', e);
    }
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      _logger.error('Error checking notification permission', e);
      return false;
    }
  }

  /// Get notification permission status
  static Future<AuthorizationStatus> getNotificationPermissionStatus() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      _logger.error('Error getting notification permission status', e);
      return AuthorizationStatus.denied;
    }
  }
}
