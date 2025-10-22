import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/app_logger.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  static MonitoringService get instance => _instance;
  MonitoringService._internal();

  final _logger = AppLogger.instance;
  bool _isInitialized = false;

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;

  /// Initialize all monitoring services
  Future<void> initialize({
    required String sentryDsn,
    String environment = 'production',
  }) async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;

      // Configure Crashlytics
      if (!kDebugMode) {
        await _crashlytics?.setCrashlyticsCollectionEnabled(true);

        // Pass uncaught errors to Crashlytics
        FlutterError.onError = _crashlytics?.recordFlutterFatalError;

        // Pass uncaught async errors
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics?.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // Initialize Sentry
      await SentryFlutter.init((options) {
        options.dsn = sentryDsn;
        options.environment = environment;
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
        options.enableAutoSessionTracking = true;
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;

        // Filter out sensitive data
        options.beforeSend = (event, {hint}) {
          // Remove sensitive headers
          event = _sanitizeEvent(event);
          return event;
        };
      });

      _isInitialized = true;
      _logger.info('Monitoring services initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize monitoring services', e);
    }
  }

  /// Log custom event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      _logger.error('Failed to log event: $name', e);
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics?.logScreenView(screenName: screenName);
    } catch (e) {
      _logger.error('Failed to log screen view: $screenName', e);
    }
  }

  /// Set user identifier
  Future<void> setUserId(String userId) async {
    try {
      await _analytics?.setUserId(id: userId);
      await _crashlytics?.setUserIdentifier(userId);
      await Sentry.configureScope((scope) {
        scope.setUser(SentryUser(id: userId));
      });
    } catch (e) {
      _logger.error('Failed to set user ID', e);
    }
  }

  /// Log custom error
  Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      // Log to Crashlytics
      await _crashlytics?.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );

      // Log to Sentry
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: reason != null ? Hint.withMap({'reason': reason}) : null,
      );

      _logger.error(reason ?? 'Error occurred', exception);
    } catch (e) {
      _logger.error('Failed to log error', e);
    }
  }

  /// Add breadcrumb for debugging
  void addBreadcrumb(String message, {String? category}) {
    try {
      _crashlytics?.log(message);
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      _logger.error('Failed to add breadcrumb', e);
    }
  }

  /// Set custom key-value for debugging
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics?.setCustomKey(key, value);
    } catch (e) {
      _logger.error('Failed to set custom key', e);
    }
  }

  /// Sanitize sensitive data from events
  SentryEvent _sanitizeEvent(SentryEvent event) {
    // Remove authorization headers
    if (event.request?.headers != null) {
      final headers = Map<String, String>.from(event.request!.headers);
      headers.remove('Authorization');
      headers.remove('authorization');

      event = event.copyWith(
        request: event.request?.copyWith(headers: headers),
      );
    }

    return event;
  }
}
