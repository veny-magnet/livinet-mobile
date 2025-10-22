import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

class FcmService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final _logger = AppLogger.instance;

  /// Initialize FCM and request permission
  static Future<void> initialize() async {
    // Request permission for notifications
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get initial FCM token
    await getFcmToken();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _saveFcmToken(token);
    });
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

  /// Get device FCM token for registration/login
  static Future<String> getTokenForRegistration() async {
    // Try to get fresh token
    String? token = await getFcmToken();

    // If failed, try to get saved token
    if (token == null) {
      token = await getSavedFcmToken();
    }

    // If still no token, return default/fallback
    return token ?? 'no-fcm-token-available';
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
}
