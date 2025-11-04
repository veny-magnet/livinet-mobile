import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'app_logger.dart';

class SessionManager with WidgetsBindingObserver {
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();
  SessionManager._();

  static const String _sessionKey = 'session_timestamp';
  static const String _lastActivityKey = 'last_activity';
  static const Duration sessionDuration = Duration(minutes: 5);
  static const Duration inactivityTimeout = Duration(
    minutes: 3,
  ); // Auto logout after 3 minutes inactivity

  Timer? _sessionTimer;
  Timer? _inactivityTimer;
  final AppLogger _logger = AppLogger.instance;

  // Global context untuk show dialog
  BuildContext? _context;
  bool _isShowingDialog = false;
  DateTime? _lastInteraction;
  bool _isAppInBackground = false;

  /// Set global context for showing dialogs
  void setContext(BuildContext context) {
    _context = context;
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  /// Start session timer
  Future<void> startSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(_sessionKey, now.toIso8601String());
      await prefs.setString(_lastActivityKey, now.toIso8601String());

      _logger.info('Session started at: ${now.toIso8601String()}');

      // Cancel existing timers
      _sessionTimer?.cancel();

      // Set session expiry timer (no warning dialog)
      _sessionTimer = Timer(sessionDuration, () {
        _handleSessionExpired();
      });

      // Start inactivity timer
      _startInactivityTimer();

      _logger.info(
        'Session timer set for ${sessionDuration.inMinutes} minutes with inactivity timeout of ${inactivityTimeout.inMinutes} minutes',
      );
    } catch (e) {
      _logger.error('Error starting session', e);
    }
  }

  /// Start inactivity timer for auto logout
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _lastInteraction = DateTime.now();

    _inactivityTimer = Timer.periodic(Duration(seconds: 60), (timer) {
      _checkInactivity();
    });
  }

  /// Check for user inactivity
  void _checkInactivity() {
    if (_lastInteraction == null) return;

    final now = DateTime.now();
    final timeSinceLastInteraction = now.difference(_lastInteraction!);

    if (timeSinceLastInteraction >= inactivityTimeout) {
      _logger.warning(
        'User inactive for ${timeSinceLastInteraction.inMinutes} minutes - logging out',
      );
      _handleSessionExpired();
    }
  }

  /// Track user interaction (call this on any user activity)
  void trackUserInteraction() {
    _lastInteraction = DateTime.now();
    _logger.debug('User interaction tracked at ${DateTime.now()}');
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _isAppInBackground = true;
        _logger.info('App moved to background');
        break;
      case AppLifecycleState.resumed:
        if (_isAppInBackground) {
          _isAppInBackground = false;
          _logger.info('App resumed from background');
          _checkBackgroundTime();
        }
        break;
      default:
        break;
    }
  }

  /// Check if app was in background too long
  void _checkBackgroundTime() {
    if (_lastInteraction == null) return;

    final now = DateTime.now();
    final timeSinceLastInteraction = now.difference(_lastInteraction!);

    if (timeSinceLastInteraction >= inactivityTimeout) {
      _logger.warning(
        'App was in background for ${timeSinceLastInteraction.inMinutes} minutes - logging out',
      );
      _handleSessionExpired();
    } else {
      // Reset interaction time when app resumes
      trackUserInteraction();
    }
  }

  /// Update last activity timestamp
  Future<void> updateActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());

      // Track user interaction
      trackUserInteraction();

      // Reset session timer on activity
      if (await isSessionValid()) {
        await startSession(); // Reset timer
      }
    } catch (e) {
      _logger.error('Error updating activity', e);
    }
  }

  /// Check if session is valid
  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionTimeString = prefs.getString(_sessionKey);

      if (sessionTimeString == null) {
        _logger.debug('No session found');
        return false;
      }

      final sessionTime = DateTime.parse(sessionTimeString);
      final now = DateTime.now();
      final elapsed = now.difference(sessionTime);

      final isValid = elapsed < sessionDuration;
      _logger.debug(
        'Session valid: $isValid, elapsed: ${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s',
      );

      return isValid;
    } catch (e) {
      _logger.error('Error checking session validity', e);
      return false;
    }
  }

  /// Show session expired dialog
  void _showSessionExpiredDialog() {
    if (_context != null && !_isShowingDialog) {
      _isShowingDialog = true;
      _logger.warning('Showing session expired dialog');

      showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.access_time, color: Colors.red),
                SizedBox(width: 8),
                Text('Session Expired'),
              ],
            ),
            content: Text(
              'Your session has expired for security reasons. Please login again to continue.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _isShowingDialog = false;
                  _navigateToLogin();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CB04C),
                  foregroundColor: Colors.white,
                ),
                child: Text('Login Again'),
              ),
            ],
          );
        },
      ).then((_) {
        _isShowingDialog = false;
      });
    }
  }

  /// Handle session expired
  void _handleSessionExpired() {
    _logger.warning('Session expired - Please login again');

    // Show dialog first, then clear session
    _showSessionExpiredDialog();
    _clearSession();
  }

  /// Extend session (reset timer)
  Future<void> extendSession() async {
    _logger.info('Extending session...');
    if (await isSessionValid()) {
      await startSession(); // Reset timer
      _logger.info('Session extended successfully');
    } else {
      _logger.warning('Cannot extend expired session');
      _handleSessionExpired();
    }
  }

  /// Clear session data
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_lastActivityKey);
      await prefs.remove('auth_token');
      await prefs.remove('user_data');

      _sessionTimer?.cancel();
      _inactivityTimer?.cancel();

      _logger.info('Session data cleared');
    } catch (e) {
      _logger.error('Error clearing session', e);
    }
  }

  /// Navigate to login page
  void _navigateToLogin() {
    if (_context != null) {
      _context!.go('/login');
      _logger.info('Navigated to login page');
    }
  }

  /// Manual logout
  Future<void> logout() async {
    _logger.info('Manual logout initiated');
    await _clearSession();
    _navigateToLogin();
  }

  /// Cleanup resources when session manager is disposed
  void cleanup() {
    _sessionTimer?.cancel();
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _logger.info('SessionManager cleaned up');
  }

  /// Get session remaining time
  Future<Duration?> getRemainingTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionTimeString = prefs.getString(_sessionKey);

      if (sessionTimeString == null) return null;

      final sessionTime = DateTime.parse(sessionTimeString);
      final expiryTime = sessionTime.add(sessionDuration);
      final now = DateTime.now();

      if (now.isBefore(expiryTime)) {
        return expiryTime.difference(now);
      }

      return Duration.zero;
    } catch (e) {
      _logger.error('Error getting remaining time', e);
      return null;
    }
  }

  /// Dispose timers
  void dispose() {
    _logger.info('Session manager disposed');
  }
}
