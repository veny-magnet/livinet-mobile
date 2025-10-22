// lib/core/services/realtime/subscription_update_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../subscription_service.dart';
import '../app_logger.dart';
import '../../cache/cache_manager.dart';

/// Service untuk menangani real-time subscription updates via push notifications
///
/// Features:
/// - Subscribe to user-specific subscription update topics
/// - Auto-invalidate cache when subscription changes
/// - Handle subscription renewals, upgrades, downgrades, cancellations
/// - Broadcast subscription updates to UI via streams
class SubscriptionUpdateService {
  static final SubscriptionUpdateService _instance =
      SubscriptionUpdateService._internal();
  static SubscriptionUpdateService get instance => _instance;
  SubscriptionUpdateService._internal();

  final _logger = AppLogger.instance;
  final _messaging = FirebaseMessaging.instance;
  final _cacheManager = CacheManager.instance;

  // Stream controller for broadcasting subscription updates to UI
  final _subscriptionUpdateController =
      StreamController<SubscriptionUpdateEvent>.broadcast();
  Stream<SubscriptionUpdateEvent> get onSubscriptionUpdate =>
      _subscriptionUpdateController.stream;

  bool _isInitialized = false;
  String? _currentUserId;

  /// Initialize subscription update service for a specific user
  Future<void> initialize(String userId, {String? addressId}) async {
    if (_isInitialized && _currentUserId == userId) {
      _logger.info(
        'SubscriptionUpdateService already initialized for user: $userId',
      );
      return;
    }

    try {
      // Unsubscribe from previous user topics if switching users
      if (_currentUserId != null && _currentUserId != userId) {
        await unsubscribe(_currentUserId!);
      }

      // Subscribe to subscription updates topic for this user
      await _messaging.subscribeToTopic('subscription_updates_$userId');
      _logger.info('Subscribed to subscription_updates_$userId');

      // If addressId provided, subscribe to address-specific updates
      if (addressId != null) {
        await _messaging.subscribeToTopic(
          'subscription_updates_${userId}_address_$addressId',
        );
        _logger.info(
          'Subscribed to subscription_updates_${userId}_address_$addressId',
        );
      }

      // Setup message handlers
      _setupMessageHandlers();

      _currentUserId = userId;
      _isInitialized = true;

      _logger.info('SubscriptionUpdateService initialized for user: $userId');
    } catch (e) {
      _logger.error('Failed to initialize SubscriptionUpdateService', e);
      rethrow;
    }
  }

  /// Setup Firebase message handlers for different app states
  void _setupMessageHandlers() {
    // Foreground messages (app is open and visible)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.info(
        'Received foreground subscription update: ${message.messageId}',
      );
      _handleSubscriptionUpdate(message, isBackground: false);
    });

    // Background messages (app is minimized but running)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.info(
        'App opened from background subscription notification: ${message.messageId}',
      );
      _handleSubscriptionUpdate(message, isBackground: true);
    });
  }

  /// Handle incoming subscription update notifications
  void _handleSubscriptionUpdate(
    RemoteMessage message, {
    bool isBackground = false,
  }) {
    try {
      final data = message.data;
      final notificationType = data['type'] as String?;

      // Only process subscription-related notifications
      if (notificationType == null ||
          !notificationType.startsWith('subscription_')) {
        return;
      }

      final userId = data['user_id'] as String?;
      final addressId = data['address_id'] as String?;
      final subscriptionId = data['subscription_id'] as String?;
      final packageName = data['package_name'] as String?;
      final status = data['status'] as String?;
      final expiryDate = data['expiry_date'] as String?;

      _logger.info(
        'Processing subscription update: type=$notificationType, '
        'userId=$userId, subscriptionId=$subscriptionId, status=$status',
      );

      if (userId == null) {
        _logger.warning('Subscription update missing user_id');
        return;
      }

      // Invalidate relevant caches
      _invalidateSubscriptionCache(
        userId: userId,
        addressId: addressId,
        notificationType: notificationType,
      );

      // Broadcast event to UI
      final event = SubscriptionUpdateEvent(
        type: _mapNotificationType(notificationType),
        userId: userId,
        addressId: addressId,
        subscriptionId: subscriptionId,
        packageName: packageName,
        status: status,
        expiryDate: expiryDate != null ? DateTime.tryParse(expiryDate) : null,
        message: message.notification?.body,
        isBackground: isBackground,
        timestamp: DateTime.now(),
      );

      _subscriptionUpdateController.add(event);

      _logger.info('Subscription update event broadcasted: ${event.type}');
    } catch (e) {
      _logger.error('Error handling subscription update', e);
    }
  }

  /// Invalidate subscription cache based on notification type
  void _invalidateSubscriptionCache({
    required String userId,
    String? addressId,
    required String notificationType,
  }) {
    try {
      switch (notificationType) {
        case 'subscription_activated':
        case 'subscription_renewed':
        case 'subscription_upgraded':
        case 'subscription_downgraded':
        case 'subscription_cancelled':
        case 'subscription_expired':
        case 'subscription_suspended':
          // Invalidate all subscription caches for user
          _cacheManager.invalidatePattern('subscriptions_$userId');
          _cacheManager.invalidatePattern('active_subscription_$userId');
          _logger.info('Invalidated all subscription cache for user: $userId');

          // Also invalidate address-specific cache if provided
          if (addressId != null) {
            _cacheManager.invalidate('subscriptions_${userId}_$addressId');
            _cacheManager.invalidate(
              'active_subscription_${userId}_$addressId',
            );
            _logger.info(
              'Invalidated subscription cache for address: $addressId',
            );
          }
          break;

        case 'subscription_expiring_soon':
          // Don't invalidate cache, just notify user
          _logger.info(
            'Subscription expiring soon notification (cache not invalidated)',
          );
          break;

        default:
          // Unknown type, invalidate all to be safe
          _cacheManager.invalidatePattern('subscriptions_$userId');
          _cacheManager.invalidatePattern('active_subscription_$userId');
          _logger.warning(
            'Unknown subscription notification type: $notificationType',
          );
      }

      // Prefetch new data in background
      _prefetchSubscriptionData(userId, addressId);
    } catch (e) {
      _logger.error('Error invalidating subscription cache', e);
    }
  }

  /// Prefetch updated subscription data in background
  Future<void> _prefetchSubscriptionData(
    String userId,
    String? addressId,
  ) async {
    try {
      // Prefetch user subscriptions
      await SubscriptionService.instance.getUserSubscriptions(
        userId,
        forceRefresh: true,
      );
      _logger.info('Prefetched subscriptions for user: $userId');

      // Prefetch active subscription if addressId provided
      if (addressId != null) {
        await SubscriptionService.instance.getActiveSubscription(
          userId,
          forceRefresh: true,
        );
        _logger.info('Prefetched active subscription for address: $addressId');
      }
    } catch (e) {
      _logger.error('Failed to prefetch subscription data', e);
      // Non-critical, don't throw
    }
  }

  /// Map notification type string to enum
  SubscriptionUpdateType _mapNotificationType(String type) {
    switch (type) {
      case 'subscription_activated':
        return SubscriptionUpdateType.activated;
      case 'subscription_renewed':
        return SubscriptionUpdateType.renewed;
      case 'subscription_upgraded':
        return SubscriptionUpdateType.upgraded;
      case 'subscription_downgraded':
        return SubscriptionUpdateType.downgraded;
      case 'subscription_cancelled':
        return SubscriptionUpdateType.cancelled;
      case 'subscription_expired':
        return SubscriptionUpdateType.expired;
      case 'subscription_suspended':
        return SubscriptionUpdateType.suspended;
      case 'subscription_expiring_soon':
        return SubscriptionUpdateType.expiringSoon;
      default:
        return SubscriptionUpdateType.unknown;
    }
  }

  /// Subscribe to address-specific subscription updates
  Future<void> subscribeToAddress(String userId, String addressId) async {
    try {
      await _messaging.subscribeToTopic(
        'subscription_updates_${userId}_address_$addressId',
      );
      _logger.info(
        'Subscribed to subscription updates for address: $addressId',
      );
    } catch (e) {
      _logger.error('Failed to subscribe to address subscription updates', e);
    }
  }

  /// Unsubscribe from address-specific subscription updates
  Future<void> unsubscribeFromAddress(String userId, String addressId) async {
    try {
      await _messaging.unsubscribeFromTopic(
        'subscription_updates_${userId}_address_$addressId',
      );
      _logger.info(
        'Unsubscribed from subscription updates for address: $addressId',
      );
    } catch (e) {
      _logger.error(
        'Failed to unsubscribe from address subscription updates',
        e,
      );
    }
  }

  /// Unsubscribe from all subscription update topics
  Future<void> unsubscribe(String userId) async {
    try {
      await _messaging.unsubscribeFromTopic('subscription_updates_$userId');
      _logger.info('Unsubscribed from subscription_updates_$userId');

      _isInitialized = false;
      _currentUserId = null;
    } catch (e) {
      _logger.error('Failed to unsubscribe from subscription updates', e);
    }
  }

  /// Dispose resources
  void dispose() {
    _subscriptionUpdateController.close();
    _isInitialized = false;
    _currentUserId = null;
  }
}

/// Subscription update event types
enum SubscriptionUpdateType {
  activated, // New subscription activated
  renewed, // Subscription renewed
  upgraded, // Subscription upgraded to higher tier
  downgraded, // Subscription downgraded to lower tier
  cancelled, // Subscription cancelled by user
  expired, // Subscription expired
  suspended, // Subscription suspended (payment failed, etc)
  expiringSoon, // Subscription expiring soon (warning)
  unknown, // Unknown type
}

/// Subscription update event data
class SubscriptionUpdateEvent {
  final SubscriptionUpdateType type;
  final String userId;
  final String? addressId;
  final String? subscriptionId;
  final String? packageName;
  final String? status;
  final DateTime? expiryDate;
  final String? message;
  final bool isBackground;
  final DateTime timestamp;

  SubscriptionUpdateEvent({
    required this.type,
    required this.userId,
    this.addressId,
    this.subscriptionId,
    this.packageName,
    this.status,
    this.expiryDate,
    this.message,
    required this.isBackground,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'SubscriptionUpdateEvent(type: $type, userId: $userId, '
        'subscriptionId: $subscriptionId, status: $status, expiryDate: $expiryDate)';
  }
}
