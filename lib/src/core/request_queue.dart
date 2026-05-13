import 'dart:async';

/// Serializes concurrent permission requests.
///
/// Multiple call sites firing `PermissionWizard.request()` simultaneously
/// would otherwise stack dialogs on top of each other. This queue ensures
/// at most one wizard is visible at a time; subsequent requests await the
/// preceding one to finish.
///
/// Implemented as a simple FIFO of futures. Cheap when idle (no allocations
/// once the queue drains).
class RequestQueue {
  Future<void>? _tail;
  int _pending = 0;

  /// Enqueue [job]. Returns a future that completes with [job]'s value
  /// once every prior job has resolved.
  Future<T> enqueue<T>(Future<T> Function() job) {
    final completer = Completer<T>();
    _pending += 1;
    // Use a fresh `Future.value()` (created in the *current* zone) when
    // nothing else is pending. This avoids chaining on a future created in
    // a dead zone (e.g. across Flutter widget tests).
    final previous = _tail ?? Future<void>.value();
    _tail = previous.then((_) async {
      try {
        final result = await job();
        completer.complete(result);
      } catch (error, stack) {
        completer.completeError(error, stack);
      } finally {
        _pending -= 1;
        if (_pending == 0) _tail = null;
      }
    });
    return completer.future;
  }

  /// `true` when no job is currently in flight or pending.
  bool get isIdle => _pending == 0;

  /// Drop all state. Used by `PermissionWizard.debugReset()` to keep the
  /// queue from leaking futures across test zones.
  void reset() {
    _tail = null;
    _pending = 0;
  }
}
