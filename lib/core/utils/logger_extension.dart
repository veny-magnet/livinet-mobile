import '../services/app_logger.dart';

/// Extension methods for easy logging
extension LoggerExtension on Object {
  /// Get logger instance
  AppLogger get logger => AppLogger.instance;
}

/// Logging helper functions
class Log {
  static final _logger = AppLogger.instance;

  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.debug(message, error, stackTrace);
  }

  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.info(message, error, stackTrace);
  }

  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.error(message, error, stackTrace);
  }

  static void f(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.fatal(message, error, stackTrace);
  }

  static void navigation(String from, String to) {
    _logger.navigation(from, to);
  }

  static void userAction(String action, [Map<String, dynamic>? data]) {
    _logger.userAction(action, data);
  }

  static void breadcrumb(String message) {
    _logger.breadcrumb(message);
  }
}
