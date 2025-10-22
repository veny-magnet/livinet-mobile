// lib/core/services/realtime/bill_update_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../bill_service.dart';
import '../app_logger.dart';
import '../../cache/cache_manager.dart';
import '../../models/bill_models.dart';

class BillUpdateService {
  static final BillUpdateService _instance = BillUpdateService._internal();
  static BillUpdateService get instance => _instance;
  BillUpdateService._internal();

  final _logger = AppLogger.instance;
  final _messaging = FirebaseMessaging.instance;
  final _cacheManager = CacheManager.instance;

  // Stream controller for broadcasting bill updates to UI
  final _billUpdateController = StreamController<BillUpdateEvent>.broadcast();
  Stream<BillUpdateEvent> get onBillUpdate => _billUpdateController.stream;

  bool _isInitialized = false;
  String? _currentUserId;

  /// Initialize bill update service for a specific user
  Future<void> initialize(String userId, {String? addressId}) async {
    if (_isInitialized && _currentUserId == userId) {
      _logger.info('BillUpdateService already initialized for user: $userId');
      return;
    }

    try {
      // Unsubscribe from previous user topics if switching users
      if (_currentUserId != null && _currentUserId != userId) {
        await unsubscribe(_currentUserId!);
      }

      // Subscribe to bill updates topic for this user
      await _messaging.subscribeToTopic('bill_updates_$userId');
      _logger.info('Subscribed to bill_updates_$userId');

      // If addressId provided, subscribe to address-specific updates
      if (addressId != null) {
        await _messaging.subscribeToTopic(
          'bill_updates_${userId}_address_$addressId',
        );
        _logger.info('Subscribed to bill_updates_${userId}_address_$addressId');
      }

      // Setup message handlers
      _setupMessageHandlers();

      _currentUserId = userId;
      _isInitialized = true;

      _logger.info('BillUpdateService initialized for user: $userId');
    } catch (e) {
      _logger.error('Failed to initialize BillUpdateService', e);
      rethrow;
    }
  }

  /// Setup Firebase message handlers for different app states
  void _setupMessageHandlers() {
    // Foreground messages (app is open and visible)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.info('Received foreground bill update: ${message.messageId}');
      _handleBillUpdate(message, isBackground: false);
    });

    // Background messages (app is minimized but running)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.info(
        'App opened from background bill notification: ${message.messageId}',
      );
      _handleBillUpdate(message, isBackground: true);
    });
  }

  /// Handle incoming bill update notifications
  void _handleBillUpdate(RemoteMessage message, {bool isBackground = false}) {
    try {
      final data = message.data;
      final notificationType = data['type'] as String?;

      // Only process bill-related notifications
      if (notificationType == null || !notificationType.startsWith('bill_')) {
        return;
      }

      final userId = data['user_id'] as String?;
      final addressId = data['address_id'] as String?;
      final invoiceId = data['invoice_id'] as String?;
      final billStatus = data['bill_status'] as String?;
      final amount = data['amount'] as String?;

      _logger.info(
        'Processing bill update: type=$notificationType, '
        'userId=$userId, invoiceId=$invoiceId, status=$billStatus',
      );

      if (userId == null) {
        _logger.warning('Bill update missing user_id');
        return;
      }

      // Invalidate relevant caches
      _invalidateBillCache(
        userId: userId,
        addressId: addressId,
        notificationType: notificationType,
      );

      // Broadcast event to UI
      final event = BillUpdateEvent(
        type: _mapNotificationType(notificationType),
        userId: userId,
        addressId: addressId,
        invoiceId: invoiceId,
        billStatus: billStatus,
        amount: amount != null ? double.tryParse(amount) : null,
        message: message.notification?.body,
        isBackground: isBackground,
        timestamp: DateTime.now(),
      );

      _billUpdateController.add(event);

      _logger.info('Bill update event broadcasted: ${event.type}');
    } catch (e) {
      _logger.error('Error handling bill update', e);
    }
  }

  /// Invalidate bill cache based on notification type
  void _invalidateBillCache({
    required String userId,
    String? addressId,
    required String notificationType,
  }) {
    try {
      switch (notificationType) {
        case 'bill_status_update':
        case 'bill_payment_received':
        case 'bill_overdue':
          // Invalidate all bills for user
          _cacheManager.invalidatePattern('bills_$userId');
          _logger.info('Invalidated all bills cache for user: $userId');

          // Also invalidate address-specific cache if provided
          if (addressId != null) {
            _cacheManager.invalidate('bills_${userId}_$addressId');
            _logger.info('Invalidated bills cache for address: $addressId');
          }
          break;

        case 'bill_generated':
          // New bill generated, invalidate to show it
          _cacheManager.invalidatePattern('bills_$userId');
          _logger.info('Invalidated bills cache (new bill generated)');
          break;

        default:
          // Unknown type, invalidate all to be safe
          _cacheManager.invalidatePattern('bills_$userId');
          _logger.warning('Unknown bill notification type: $notificationType');
      }

      // Also prefetch new data in background
      _prefetchBillData(userId, addressId);
    } catch (e) {
      _logger.error('Error invalidating bill cache', e);
    }
  }

  /// Prefetch updated bill data in background
  Future<void> _prefetchBillData(String userId, String? addressId) async {
    try {
      if (addressId != null) {
        // Prefetch bills for specific address
        final request = BillHistoryRequest(
          userId: userId,
          userAddressId: int.parse(addressId),
        );
        await BillService.instance.getBillHistory(request, forceRefresh: true);
        _logger.info('Prefetched bills for address: $addressId');
      }
    } catch (e) {
      _logger.error('Failed to prefetch bill data', e);
      // Non-critical, don't throw
    }
  }

  /// Map notification type string to enum
  BillUpdateType _mapNotificationType(String type) {
    switch (type) {
      case 'bill_status_update':
        return BillUpdateType.statusUpdate;
      case 'bill_payment_received':
        return BillUpdateType.paymentReceived;
      case 'bill_overdue':
        return BillUpdateType.overdue;
      case 'bill_generated':
        return BillUpdateType.newBillGenerated;
      default:
        return BillUpdateType.unknown;
    }
  }

  /// Subscribe to address-specific bill updates
  Future<void> subscribeToAddress(String userId, String addressId) async {
    try {
      await _messaging.subscribeToTopic(
        'bill_updates_${userId}_address_$addressId',
      );
      _logger.info('Subscribed to bill updates for address: $addressId');
    } catch (e) {
      _logger.error('Failed to subscribe to address bill updates', e);
    }
  }

  /// Unsubscribe from address-specific bill updates
  Future<void> unsubscribeFromAddress(String userId, String addressId) async {
    try {
      await _messaging.unsubscribeFromTopic(
        'bill_updates_${userId}_address_$addressId',
      );
      _logger.info('Unsubscribed from bill updates for address: $addressId');
    } catch (e) {
      _logger.error('Failed to unsubscribe from address bill updates', e);
    }
  }

  /// Unsubscribe from all bill update topics
  Future<void> unsubscribe(String userId) async {
    try {
      await _messaging.unsubscribeFromTopic('bill_updates_$userId');
      _logger.info('Unsubscribed from bill_updates_$userId');

      _isInitialized = false;
      _currentUserId = null;
    } catch (e) {
      _logger.error('Failed to unsubscribe from bill updates', e);
    }
  }

  /// Dispose resources
  void dispose() {
    _billUpdateController.close();
    _isInitialized = false;
    _currentUserId = null;
  }
}

/// Bill update event types
enum BillUpdateType {
  statusUpdate,
  paymentReceived,
  overdue,
  newBillGenerated,
  unknown,
}

/// Bill update event data
class BillUpdateEvent {
  final BillUpdateType type;
  final String userId;
  final String? addressId;
  final String? invoiceId;
  final String? billStatus;
  final double? amount;
  final String? message;
  final bool isBackground;
  final DateTime timestamp;

  BillUpdateEvent({
    required this.type,
    required this.userId,
    this.addressId,
    this.invoiceId,
    this.billStatus,
    this.amount,
    this.message,
    required this.isBackground,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'BillUpdateEvent(type: $type, userId: $userId, '
        'invoiceId: $invoiceId, status: $billStatus, amount: $amount)';
  }
}
