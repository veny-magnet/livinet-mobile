import 'auth_service.dart';
import '../monitoring/monitoring_service.dart';
import 'app_logger.dart';

class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  static AppInitializer get instance => _instance;
  AppInitializer._internal();

  final _logger = AppLogger.instance;
  bool _isInitialized = false;

  Future<Map<String, dynamic>> initialize() async {
    if (_isInitialized) {
      return {'success': true, 'message': 'Already initialized'};
    }

    final stopwatch = Stopwatch()..start();

    try {
      final authValidation = await _validateAuth();

      if (!authValidation['success']) {
        return authValidation;
      }

      final userId = authValidation['userId'] as String?;

      // Set user identifier for monitoring
      if (userId != null) {
        await MonitoringService.instance.setUserId(userId);
      }

      _isInitialized = true;
      stopwatch.stop();

      _logger.info(
        'App initialization completed in ${stopwatch.elapsedMilliseconds}ms',
      );
      MonitoringService.instance.logEvent(
        'app_initialized',
        parameters: {'duration_ms': stopwatch.elapsedMilliseconds},
      );

      return {
        'success': true,
        'message': 'Initialization successful',
        'userId': userId,
      };
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.error('App initialization failed', e, stackTrace);
      MonitoringService.instance.logError(
        e,
        stackTrace,
        reason: 'App initialization failed',
      );

      return {'success': false, 'message': 'Initialization failed: $e'};
    }
  }

  /// Validate authentication only
  Future<Map<String, dynamic>> _validateAuth() async {
    try {
      final authService = AuthService();

      // Check authentication
      final currentUser = await authService.getCurrentUser();

      if (currentUser == null || currentUser['code'] == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final userId = currentUser['code'] as String;

      return {'success': true, 'userId': userId};
    } catch (e) {
      _logger.error('Failed to validate auth', e);
      return {'success': false, 'message': 'Authentication validation failed'};
    }
  }

  /// Reset initialization state (for logout)
  Future<void> reset() async {
    _isInitialized = false;
    _logger.info('App initializer reset');
  }
}
