import 'package:flutter/material.dart';
import 'dart:async';
import '../services/session_manager.dart';

class SessionStatusWidget extends StatefulWidget {
  const SessionStatusWidget({super.key});

  @override
  State<SessionStatusWidget> createState() => _SessionStatusWidgetState();
}

class _SessionStatusWidgetState extends State<SessionStatusWidget> {
  final SessionManager _sessionManager = SessionManager.instance;
  Timer? _updateTimer;
  Duration? _remainingTime;
  bool _isSessionValid = false;

  @override
  void initState() {
    super.initState();
    _startUpdating();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startUpdating() {
    _updateSessionInfo();
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateSessionInfo();
    });
  }

  Future<void> _updateSessionInfo() async {
    final remainingTime = await _sessionManager.getRemainingTime();
    final isValid = await _sessionManager.isSessionValid();

    if (mounted) {
      setState(() {
        _remainingTime = remainingTime;
        _isSessionValid = isValid;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!const bool.fromEnvironment('dart.vm.product')) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isSessionValid
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isSessionValid ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isSessionValid ? Icons.check_circle : Icons.error,
              color: _isSessionValid ? Colors.green : Colors.red,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              _remainingTime != null
                  ? 'Session: ${_formatDuration(_remainingTime!)}'
                  : 'No Session',
              style: TextStyle(
                fontSize: 12,
                color: _isSessionValid
                    ? Colors.green.shade800
                    : Colors.red.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }
}
