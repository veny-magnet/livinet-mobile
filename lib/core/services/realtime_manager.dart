import 'dart:async';
import 'package:flutter/material.dart';
import 'realtime_service.dart';
import 'auth_service.dart';
// UserProfileService import removed - cache clearing no longer needed
import 'app_logger.dart';

/// Helper class to integrate realtime updates with the application
class RealtimeManager {
  static final RealtimeManager _instance = RealtimeManager._internal();
  static RealtimeManager get instance => _instance;

  RealtimeManager._internal();

  final _logger = AppLogger.instance;
  final _realtimeService = RealtimeService.instance;
  bool _isInitialized = false;
  StreamSubscription? _userUpdateSubscription;

  /// Initialize realtime connection after login
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) {
      _logger.info('Realtime manager already initialized');
      return;
    }

    try {
      // Get current user and token
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      final token = await authService.getAuthToken();

      if (currentUser == null || token == null) {
        _logger.warning('Cannot initialize realtime: No user session');
        return;
      }

      final userId = currentUser['code'] as String?;
      if (userId == null) {
        _logger.warning('Cannot initialize realtime: No user code');
        return;
      }

      // Register callbacks
      _registerCallbacks(context);

      // Connect to WebSocket menggunakan userCode (UUID)
      await _realtimeService.connect(userId, token);

      _isInitialized = true;
      _logger.info('Realtime manager initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize realtime manager', e, stackTrace);
    }
  }

  /// Register all callbacks for realtime events
  void _registerCallbacks(BuildContext context) {
    // User update callback
    _realtimeService.onUserUpdate((userData) {
      _handleUserUpdate(context, userData);
    });

    // Connection status callback
    _realtimeService.onConnectionStatusChange((isConnected) {
      _handleConnectionStatusChange(context, isConnected);
    });

    // Force logout callback
    _realtimeService.onForceLogout((reason) {
      _handleForceLogout(context, reason);
    });
  }

  /// Handle user data updates from server
  void _handleUserUpdate(BuildContext context, Map<String, dynamic> userData) {
    _logger.info('Received user update from server');

    // Cache clearing removed - no longer needed

    // Show notification to user
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Your profile has been updated by admin')),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Refresh',
            textColor: Colors.white,
            onPressed: () {
              // Trigger app refresh or navigation
              _refreshCurrentScreen(context);
            },
          ),
        ),
      );
    }
  }

  /// Handle connection status changes
  void _handleConnectionStatusChange(BuildContext context, bool isConnected) {
    _logger.info(
      'Realtime connection status: ${isConnected ? "Connected" : "Disconnected"}',
    );

    // Optional: Show connection status to user
    if (context.mounted && !isConnected) {
      // Only show if disconnected, to avoid spam
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.signal_wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Text('Live updates disconnected. Retrying...'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle force logout from server
  void _handleForceLogout(BuildContext context, String reason) {
    _logger.warning('Force logout received: $reason');

    // Perform logout
    final authService = AuthService();
    authService.logout();

    // Disconnect realtime
    disconnect();

    // Show dialog and navigate to login
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 12),
                Text('Session Ended'),
              ],
            ),
            content: Text(
              reason.isEmpty
                  ? 'Your account has been updated. Please login again.'
                  : reason,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Navigate to login screen
                  _navigateToLogin(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  /// Refresh current screen
  void _refreshCurrentScreen(BuildContext context) {
    // Force rebuild by popping and pushing same route
    // Or use state management to trigger refresh
    if (context.mounted) {
      // This is a simple approach - you might want to use your router
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// Navigate to login screen
  void _navigateToLogin(BuildContext context) {
    if (context.mounted) {
      // Use your router to navigate to login
      // Example with go_router:
      // context.go('/login');

      // Or with Navigator:
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  /// Disconnect realtime service
  void disconnect() {
    _logger.info('Disconnecting realtime manager');
    _realtimeService.disconnect();
    _realtimeService.clearAllCallbacks();
    _userUpdateSubscription?.cancel();
    _isInitialized = false;
  }

  /// Check if realtime is connected
  bool get isConnected => _realtimeService.isConnected;

  /// Send a custom message to server
  void sendMessage(Map<String, dynamic> message) {
    _realtimeService.sendMessage(message);
  }
}
