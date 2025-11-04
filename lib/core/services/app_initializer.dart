import 'auth_service.dart';
import 'user_profile_service.dart';
import 'address_service.dart';
import '../monitoring/monitoring_service.dart';
import 'app_logger.dart';

class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  static AppInitializer get instance => _instance;
  AppInitializer._internal();

  final _logger = AppLogger.instance;
  bool _isInitialized = false;

  /// Initialize app with optimized loading
  Future<Map<String, dynamic>> initialize() async {
    if (_isInitialized) {
      return {'success': true, 'message': 'Already initialized'};
    }

    final stopwatch = Stopwatch()..start();

    try {
      final criticalData = await _loadCriticalData();

      if (!criticalData['success']) {
        return criticalData;
      }

      final userId = criticalData['userId'] as String?;

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
        'profile': criticalData['profile'],
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

  /// Load critical data (blocking)
  Future<Map<String, dynamic>> _loadCriticalData() async {
    try {
      final authService = AuthService();

      // Check authentication
      final currentUser = await authService.getCurrentUser();

      if (currentUser == null || currentUser['user_id'] == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final userId = currentUser['user_id'] as String;

      // Load user profile in parallel with address check
      final results = await Future.wait([
        UserProfileService.instance.getCurrentUserProfile(),
        AddressService.instance.getUserAddresses(userId),
      ]);

      final profileResult = results[0];
      final addressResult = results[1];

      if (profileResult['success'] != true) {
        return {'success': false, 'message': 'Failed to load profile'};
      }

      // Set user identifier for monitoring
      await MonitoringService.instance.setUserId(userId);

      // Real-time services disabled (not needed with cache sync)
      // await _initializeRealtimeServices(userId);

      return {
        'success': true,
        'userId': userId,
        'profile': profileResult['data'],
        'hasAddress':
            addressResult['success'] == true &&
            (addressResult['data'] as List?)?.isNotEmpty == true,
      };
    } catch (e) {
      _logger.error('Failed to load critical data', e);
      return {'success': false, 'message': 'Failed to load user data'};
    }
  }

  /// Reset initialization state (for logout)
  Future<void> reset() async {
    _isInitialized = false;
    _logger.info('App initializer reset');
  }
}
