import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads configuration from .env file
class AppEnvironment {
  static final AppEnvironment _instance = AppEnvironment._internal();
  static AppEnvironment get instance => _instance;
  AppEnvironment._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
      _initialized = true;
    } catch (e) {
      // Silently fail - will use fallback values
    }
  }

  // API Configuration
  String get apiBaseUrl => dotenv.get(
    'API_BASE_URL',
    fallback: 'https://437d3c3b6a1c.ngrok-free.app/api/v1',
  );

  int get apiTimeout => int.parse(dotenv.get('API_TIMEOUT', fallback: '30'));

  String get apiServer =>
      dotenv.get('API_SERVER', fallback: 'LIVINET_API_SERVER');
  String get apiKey => dotenv.get('API_KEY', fallback: 'LIVINET_API_KEY_12345');

  // App Configuration
  String get appName => dotenv.get('APP_NAME', fallback: 'Livinet Mobile');
  String get appVersion => dotenv.get('APP_VERSION', fallback: '1.0.0');
  String get environment => dotenv.get('ENVIRONMENT', fallback: 'development');

  // Feature Flags
  bool get enableLogging =>
      dotenv.get('ENABLE_LOGGING', fallback: 'true') == 'true';
  bool get enableCrashlytics =>
      dotenv.get('ENABLE_CRASHLYTICS', fallback: 'false') == 'true';

  // Monitoring
  String get sentryDsn => dotenv.get('SENTRY_DSN', fallback: '');

  // Cache Configuration
  int get cacheExpiryMinutes =>
      int.parse(dotenv.get('CACHE_EXPIRY_MINUTES', fallback: '5'));

  // Environment checks
  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';

  /// Get all configuration as Map (for debugging)
  Map<String, dynamic> toMap() {
    return {
      'apiBaseUrl': apiBaseUrl,
      'apiTimeout': apiTimeout,
      'appName': appName,
      'appVersion': appVersion,
      'environment': environment,
      'enableLogging': enableLogging,
      'enableCrashlytics': enableCrashlytics,
      'sentryDsn': sentryDsn.isNotEmpty ? '***configured***' : 'not set',
      'cacheExpiryMinutes': cacheExpiryMinutes,
    };
  }
}
