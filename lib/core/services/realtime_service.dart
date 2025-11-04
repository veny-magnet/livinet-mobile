import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../config/app_config.dart';
import 'app_logger.dart';
// UserProfileService import removed - cache clearing no longer needed

/// Real-time service for WebSocket connections
/// Handles live updates from server
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  static RealtimeService get instance => _instance;

  RealtimeService._internal();

  WebSocket? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  final _logger = AppLogger.instance;
  final _config = AppConfig.instance;

  // Callbacks for different events
  final List<Function(Map<String, dynamic>)> _userUpdateCallbacks = [];
  final List<Function(bool)> _connectionStatusCallbacks = [];
  final List<Function(String)> _forceLogoutCallbacks = [];

  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<void> connect(String userId, String token) async {
    if (_isConnected && _channel != null) {
      _logger.info('WebSocket already connected');
      return;
    }

    try {
      _shouldReconnect = true;
      _reconnectAttempts = 0;

      // Build WebSocket URL from base URL
      final baseUrl = _config.baseUrl;
      final wsUrl = baseUrl
          .replaceFirst('http', 'ws')
          .replaceFirst('https', 'wss');
      final url = '$wsUrl/ws/user/$userId?token=$token';

      _logger.info('Connecting to WebSocket: $url');

      _channel = await WebSocket.connect(url);

      // Listen to messages
      _channel!.listen(
        (message) => _handleMessage(message),
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _notifyConnectionStatus(true);
      _startHeartbeat();

      _logger.info('WebSocket connected successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to connect WebSocket', e, stackTrace);
      _isConnected = false;
      _notifyConnectionStatus(false);
      _scheduleReconnect(userId, token);
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      _logger.debug('WebSocket message received: $data');

      final messageType = data['type'] as String?;

      switch (messageType) {
        case 'user_updated':
          _handleUserUpdate(data);
          break;

        case 'profile_updated':
          _handleProfileUpdate(data);
          break;

        case 'role_changed':
          _handleRoleChange(data);
          break;

        case 'force_logout':
          _handleForceLogout(data);
          break;

        case 'pong':
          _logger.debug('Heartbeat acknowledged');
          break;

        default:
          _logger.warning('Unknown message type: $messageType');
      }
    } catch (e, stackTrace) {
      _logger.error('Error handling WebSocket message', e, stackTrace);
    }
  }

  /// Handle user data update
  Future<void> _handleUserUpdate(Map<String, dynamic> data) async {
    try {
      final userData = data['user'] as Map<String, dynamic>?;
      if (userData == null) return;

      _logger.info('User data updated from server');

      // Cache clearing removed - no longer needed

      // Notify all registered callbacks
      for (final callback in _userUpdateCallbacks) {
        try {
          callback(userData);
        } catch (e) {
          _logger.error('Error in user update callback', e);
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Error handling user update', e, stackTrace);
    }
  }

  /// Handle profile update
  Future<void> _handleProfileUpdate(Map<String, dynamic> data) async {
    try {
      _logger.info('Profile updated from server');

      // Cache clearing removed - no longer needed

      // Notify callbacks
      final profileData = data['profile'] as Map<String, dynamic>? ?? {};
      for (final callback in _userUpdateCallbacks) {
        try {
          callback(profileData);
        } catch (e) {
          _logger.error('Error in profile update callback', e);
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Error handling profile update', e, stackTrace);
    }
  }

  /// Handle role change
  Future<void> _handleRoleChange(Map<String, dynamic> data) async {
    try {
      final newRole = data['role'] as String?;
      _logger.info('User role changed to: $newRole');

      // Cache clearing removed - no longer needed

      // Notify callbacks to trigger re-fetch of user data
      for (final callback in _userUpdateCallbacks) {
        try {
          callback(data);
        } catch (e) {
          _logger.error('Error in role change callback', e);
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Error handling role change', e, stackTrace);
    }
  }

  /// Handle force logout
  void _handleForceLogout(Map<String, dynamic> data) {
    try {
      final reason = data['reason'] as String? ?? 'Account updated by admin';
      _logger.warning('Force logout: $reason');

      // Notify all logout callbacks
      for (final callback in _forceLogoutCallbacks) {
        try {
          callback(reason);
        } catch (e) {
          _logger.error('Error in force logout callback', e);
        }
      }

      // Disconnect WebSocket
      disconnect();
    } catch (e, stackTrace) {
      _logger.error('Error handling force logout', e, stackTrace);
    }
  }

  /// Handle WebSocket error
  void _handleError(dynamic error) {
    _logger.error('WebSocket error', error);
    _isConnected = false;
    _notifyConnectionStatus(false);
  }

  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    _logger.warning('WebSocket disconnected');
    _isConnected = false;
    _notifyConnectionStatus(false);
    _stopHeartbeat();

    if (_shouldReconnect) {
      _reconnectAttempts++;
      if (_reconnectAttempts <= _maxReconnectAttempts) {
        _logger.info(
          'Will attempt to reconnect (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
        );
      }
    }
  }

  /// Schedule reconnection
  void _scheduleReconnect(String userId, String token) {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      _logger.warning(
        'Max reconnect attempts reached or reconnection disabled',
      );
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _logger.info('Attempting to reconnect...');
      connect(userId, token);
    });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          _logger.error('Failed to send heartbeat', e);
        }
      }
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Send message to server
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.add(jsonEncode(message));
      } catch (e) {
        _logger.error('Failed to send WebSocket message', e);
      }
    } else {
      _logger.warning('Cannot send message: WebSocket not connected');
    }
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _logger.info('Disconnecting WebSocket');
    _shouldReconnect = false;
    _isConnected = false;
    _stopHeartbeat();
    _reconnectTimer?.cancel();

    try {
      _channel?.close();
    } catch (e) {
      _logger.error('Error closing WebSocket', e);
    }

    _channel = null;
    _notifyConnectionStatus(false);
  }

  /// Register callback for user updates
  void onUserUpdate(Function(Map<String, dynamic>) callback) {
    _userUpdateCallbacks.add(callback);
  }

  /// Remove user update callback
  void removeUserUpdateCallback(Function(Map<String, dynamic>) callback) {
    _userUpdateCallbacks.remove(callback);
  }

  /// Register callback for connection status changes
  void onConnectionStatusChange(Function(bool) callback) {
    _connectionStatusCallbacks.add(callback);
  }

  /// Remove connection status callback
  void removeConnectionStatusCallback(Function(bool) callback) {
    _connectionStatusCallbacks.remove(callback);
  }

  /// Register callback for force logout
  void onForceLogout(Function(String) callback) {
    _forceLogoutCallbacks.add(callback);
  }

  /// Remove force logout callback
  void removeForceLogoutCallback(Function(String) callback) {
    _forceLogoutCallbacks.remove(callback);
  }

  /// Notify connection status change
  void _notifyConnectionStatus(bool isConnected) {
    for (final callback in _connectionStatusCallbacks) {
      try {
        callback(isConnected);
      } catch (e) {
        _logger.error('Error in connection status callback', e);
      }
    }
  }

  /// Clear all callbacks
  void clearAllCallbacks() {
    _userUpdateCallbacks.clear();
    _connectionStatusCallbacks.clear();
    _forceLogoutCallbacks.clear();
  }
}
