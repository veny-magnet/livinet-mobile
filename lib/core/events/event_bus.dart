import 'dart:async';

/// Simple event bus implementation without external dependencies
class AppEventBus {
  static final AppEventBus _instance = AppEventBus._internal();

  final Map<Type, StreamController> _streamControllers = {};

  AppEventBus._internal();

  static AppEventBus get instance => _instance;

  /// Fire an event
  void fire(dynamic event) {
    final type = event.runtimeType;
    if (_streamControllers.containsKey(type)) {
      _streamControllers[type]!.add(event);
    }
  }

  /// Listen to events of type T
  Stream<T> on<T>() {
    if (!_streamControllers.containsKey(T)) {
      _streamControllers[T] = StreamController<T>.broadcast();
    }
    return _streamControllers[T]!.stream as Stream<T>;
  }

  /// Destroy the event bus (useful for testing)
  void destroy() {
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
}
