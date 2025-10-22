import 'auth_service.dart';
import 'user_profile_service.dart';
import 'address_service.dart';
import 'product_service.dart';
import '../cache/cache_manager.dart';
import '../monitoring/monitoring_service.dart';
import 'app_logger.dart';
import 'realtime/bill_update_service.dart';
import 'realtime/subscription_update_service.dart';
import 'realtime/user_profile_update_service.dart';
import 'address_manager.dart';

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
      // Phase 1: Initialize core services (parallel)
      _logger.info('Phase 1: Initializing core services...');
      await Future.wait([
        CacheManager.instance.init(),
        // MonitoringService already initialized in main()
      ]);

      // Phase 2: Load critical user data (parallel)
      _logger.info('Phase 2: Loading critical data...');
      final criticalData = await _loadCriticalData();

      if (!criticalData['success']) {
        return criticalData;
      }

      final userId = criticalData['userId'] as String?;

      if (userId != null) {
        // Phase 3: Prefetch non-critical data (background)
        _prefetchNonCriticalData(userId);
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

      // Initialize real-time notification services
      await _initializeRealtimeServices(userId);

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

  /// Prefetch non-critical data (non-blocking)
  void _prefetchNonCriticalData(String userId) {
    _logger.info('Prefetching non-critical data...');

    // Run in background
    Future.wait([_prefetchProducts(userId), _prefetchSubscriptions(userId)])
        .then((_) {
          _logger.info('Non-critical data prefetch completed');
        })
        .catchError((e) {
          _logger.warning('Non-critical data prefetch failed', e);
        });
  }

  Future<void> _prefetchProducts(String userId) async {
    try {
      final addressResult = await AddressService.instance.getUserAddresses(
        userId,
      );

      if (addressResult['success'] == true && addressResult['data'] != null) {
        final addresses = addressResult['data'] as List;
        if (addresses.isNotEmpty) {
          final firstAddress = addresses.first;
          await ProductService.instance.getProducts(
            userId: userId,
            addressId: firstAddress.addressId,
          );
        }
      }
    } catch (e) {
      _logger.debug('Product prefetch failed', e);
    }
  }

  Future<void> _prefetchSubscriptions(String userId) async {
    try {
      // Add your subscription prefetch logic here
      // await SubscriptionService.instance.getUserSubscriptions(userId);
    } catch (e) {
      _logger.debug('Subscription prefetch failed', e);
    }
  }

  /// Initialize real-time notification services
  Future<void> _initializeRealtimeServices(String userId) async {
    try {
      _logger.info('Initializing real-time notification services...');

      // Get selected address if available
      final selectedAddressId = AddressManager.instance.selectedAddressId;

      // Initialize services in parallel
      await Future.wait([
        BillUpdateService.instance.initialize(
          userId,
          addressId: selectedAddressId?.toString(),
        ),
        SubscriptionUpdateService.instance.initialize(
          userId,
          addressId: selectedAddressId?.toString(),
        ),
        UserProfileUpdateService.instance.initialize(userId),
      ]);

      _logger.info('Real-time notification services initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize real-time services', e);
      // Don't throw - real-time services are non-critical
    }
  }

  /// Reset initialization state (for logout)
  Future<void> reset() async {
    _isInitialized = false;
    _logger.info('App initializer reset');

    // Cleanup real-time services
    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      final userId = currentUser?['user_id'] as String?;

      if (userId != null) {
        await BillUpdateService.instance.unsubscribe(userId);
        await SubscriptionUpdateService.instance.unsubscribe(userId);
        await UserProfileUpdateService.instance.unsubscribe(userId);
        _logger.info('Real-time services unsubscribed');
      }
    } catch (e) {
      _logger.error('Failed to cleanup real-time services', e);
    }
  }
}
