import 'package:flutter/material.dart';
import '../services/session_manager.dart';

/// Wrapper widget that tracks user interactions for session management
class UserInteractionTracker extends StatelessWidget {
  final Widget child;

  const UserInteractionTracker({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Track all types of user interactions
      onTap: () => SessionManager.instance.trackUserInteraction(),
      onPanDown: (_) => SessionManager.instance.trackUserInteraction(),
      onScaleStart: (_) => SessionManager.instance.trackUserInteraction(),

      // Use Listener for additional interaction types
      child: Listener(
        onPointerDown: (_) => SessionManager.instance.trackUserInteraction(),
        onPointerMove: (_) => SessionManager.instance.trackUserInteraction(),
        onPointerSignal: (_) => SessionManager.instance.trackUserInteraction(),

        child: child,
      ),
    );
  }
}

/// Mixin for screens that need to track user interactions
mixin UserActivityTracker<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    // Track screen initialization as user activity
    SessionManager.instance.trackUserInteraction();
  }

  /// Call this method whenever user performs an action
  void trackActivity() {
    SessionManager.instance.trackUserInteraction();
  }

  /// Wrap any interactive widget with this to auto-track interactions
  Widget trackInteraction(Widget child) {
    return GestureDetector(
      onTap: () => trackActivity(),
      onPanDown: (_) => trackActivity(),
      onScaleStart: (_) => trackActivity(),
      child: child,
    );
  }
}
