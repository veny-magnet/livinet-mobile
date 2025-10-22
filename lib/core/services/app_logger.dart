import 'package:logger/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../config/app_config.dart';
import 'package:flutter/foundation.dart';

/// Application-wide logging service
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  static AppLogger get instance => _instance;
  factory AppLogger() => _instance;
  AppLogger._internal();

  final _config = AppConfig.instance;
  late final Logger _logger;
  bool _initialized = false;

  /// Initialize logger
  void initialize() {
    if (_initialized) return;

    _logger = Logger(
      filter: _LogFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      output: _LogOutput(),
    );

    _initialized = true;
  }

  /// Debug log - for debugging purposes only
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_config.isLoggingEnabled) return;
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info log - for general information
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_config.isLoggingEnabled) return;
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning log - for potential issues
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_config.isLoggingEnabled) return;
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error log - for errors that need attention
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);

    // Send to Crashlytics in production
    if (_config.isCrashlyticsEnabled && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    }
  }

  /// Fatal log - for critical errors
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);

    // Send to Crashlytics
    if (_config.isCrashlyticsEnabled && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: true,
      );
    }
  }

  /// Log API request
  void apiRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (!_config.isLoggingEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('🌐 API REQUEST');
    buffer.writeln('Method: $method');
    buffer.writeln('Endpoint: $endpoint');

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('Headers: $headers');
    }

    if (body != null) {
      buffer.writeln('Body: $body');
    }

    _logger.d(buffer.toString());
  }

  /// Log API response
  void apiResponse({
    required String endpoint,
    required int statusCode,
    dynamic body,
    Duration? duration,
  }) {
    if (!_config.isLoggingEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('📨 API RESPONSE');
    buffer.writeln('Endpoint: $endpoint');
    buffer.writeln('Status: $statusCode');

    if (duration != null) {
      buffer.writeln('Duration: ${duration.inMilliseconds}ms');
    }

    if (body != null) {
      buffer.writeln('Body: $body');
    }

    if (statusCode >= 200 && statusCode < 300) {
      _logger.i(buffer.toString());
    } else if (statusCode >= 400) {
      _logger.e(buffer.toString());
    } else {
      _logger.w(buffer.toString());
    }
  }

  /// Log navigation event
  void navigation(String from, String to) {
    if (!_config.isLoggingEnabled) return;
    _logger.i('🧭 Navigation: $from → $to');
  }

  /// Log user action
  void userAction(String action, [Map<String, dynamic>? data]) {
    if (!_config.isLoggingEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('👤 User Action: $action');
    if (data != null && data.isNotEmpty) {
      buffer.writeln('Data: $data');
    }

    _logger.i(buffer.toString());
  }

  /// Set user identifier for crash reports
  void setUserIdentifier(String userId, {String? email, String? name}) {
    if (_config.isCrashlyticsEnabled) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
      if (email != null || name != null) {
        FirebaseCrashlytics.instance.setCustomKey('user_email', email ?? '');
        FirebaseCrashlytics.instance.setCustomKey('user_name', name ?? '');
      }
    }
  }

  /// Set custom key for crash reports
  void setCustomKey(String key, dynamic value) {
    if (_config.isCrashlyticsEnabled) {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
  }

  /// Log breadcrumb for crash reports
  void breadcrumb(String message) {
    if (_config.isCrashlyticsEnabled) {
      FirebaseCrashlytics.instance.log(message);
    }
  }
}

/// Custom log filter
class _LogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    final config = AppConfig.instance;

    // Always log errors and fatal
    if (event.level.value >= Level.error.value) {
      return true;
    }

    // In production, only log warnings and above
    if (config.isProduction) {
      return event.level.value >= Level.warning.value;
    }

    // In development, log everything if enabled
    return config.isLoggingEnabled;
  }
}

/// Custom log output
class _LogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      // In debug mode, use print
    }
  }
}
