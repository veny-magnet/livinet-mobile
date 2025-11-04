import 'package:flutter/material.dart';
import '../services/realtime_manager.dart';

/// Widget wrapper to automatically handle realtime connection lifecycle
class RealtimeProvider extends StatefulWidget {
  final Widget child;
  final bool autoConnect;

  const RealtimeProvider({
    super.key,
    required this.child,
    this.autoConnect = true,
  });

  @override
  State<RealtimeProvider> createState() => _RealtimeProviderState();
}

class _RealtimeProviderState extends State<RealtimeProvider>
    with WidgetsBindingObserver {
  final _realtimeManager = RealtimeManager.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.autoConnect) {
      // Initialize after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _realtimeManager.initialize(context);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground, reconnect if needed
        if (!_realtimeManager.isConnected) {
          _realtimeManager.initialize(context);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App going to background, can keep connection or disconnect
        // For battery saving, you might want to disconnect:
        // _realtimeManager.disconnect();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Connection status indicator widget
class RealtimeConnectionIndicator extends StatefulWidget {
  final Widget? connectedWidget;
  final Widget? disconnectedWidget;
  final bool showAlways;

  const RealtimeConnectionIndicator({
    super.key,
    this.connectedWidget,
    this.disconnectedWidget,
    this.showAlways = false,
  });

  @override
  State<RealtimeConnectionIndicator> createState() =>
      _RealtimeConnectionIndicatorState();
}

class _RealtimeConnectionIndicatorState
    extends State<RealtimeConnectionIndicator> {
  final _realtimeManager = RealtimeManager.instance;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _isConnected = _realtimeManager.isConnected;

    // Listen to connection status changes
    // Note: You might want to use a stream or callback here
    // For now, we'll just check the status periodically
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAlways && _isConnected) {
      return const SizedBox.shrink();
    }

    if (_isConnected) {
      return widget.connectedWidget ??
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_done, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Live',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
    } else {
      return widget.disconnectedWidget ??
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Offline',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
    }
  }
}
