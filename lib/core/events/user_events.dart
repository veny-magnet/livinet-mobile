/// Event class for user data updates
class UserUpdatedEvent {
  final Map<String, dynamic> userData;
  final String updateType;

  UserUpdatedEvent({required this.userData, required this.updateType});
}

/// Event class for connection status changes
class ConnectionStatusEvent {
  final bool isConnected;
  final String? message;

  ConnectionStatusEvent({required this.isConnected, this.message});
}

/// Event class for forced logout
class ForceLogoutEvent {
  final String reason;

  ForceLogoutEvent({required this.reason});
}
