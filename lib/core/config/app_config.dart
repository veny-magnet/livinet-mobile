import 'environment.dart';

/// Application-wide configuration singleton
/// Provides centralized access to all app configuration
class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  static AppConfig get instance => _instance;
  factory AppConfig() => _instance;
  AppConfig._internal();

  final AppEnvironment _env = AppEnvironment.instance;

  // API Configuration
  String get baseUrl => _env.apiBaseUrl;
  Duration get timeout => Duration(seconds: _env.apiTimeout);
  String get apiServer => _env.apiServer;
  String get apiKey => _env.apiKey;

  // App Information
  String get appName => _env.appName;
  String get version => _env.appVersion;
  String get environment => _env.environment;

  // Feature Flags
  bool get isLoggingEnabled => _env.enableLogging;
  bool get isCrashlyticsEnabled => _env.enableCrashlytics;

  // Monitoring
  String get sentryDsn => _env.sentryDsn;

  // Cache Settings
  Duration get cacheExpiry => Duration(minutes: _env.cacheExpiryMinutes);

  // Environment Checks
  bool get isDevelopment => _env.isDevelopment;
  bool get isProduction => _env.isProduction;
  bool get isStaging => _env.isStaging;

  /// Get complete API endpoint URL
  String getEndpoint(String path) {
    // Remove leading slash if exists
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Add trailing slash to baseUrl if not exists
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

    return '$cleanBaseUrl$cleanPath';
  }

  /// Get configuration as map
  Map<String, dynamic> toMap() {
    return _env.toMap();
  }
}
