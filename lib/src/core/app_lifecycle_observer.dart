import 'dart:async';

import 'package:flutter/widgets.dart';

/// Lifecycle event surfaced to wizard internals. The wizard cares only
/// about two things: did the app go background while a dialog was visible,
/// and did the app come back to the foreground after we opened Settings.
enum AppLifecycleEvent { resumed, backgrounded }

/// Bridges Flutter's [WidgetsBindingObserver] into a broadcast stream so
/// individual wizard sessions can subscribe and detach cleanly.
///
/// Designed to be installed exactly once for the lifetime of the app — a
/// global singleton avoids the cost of attaching/detaching observers on
/// every request. The wizard's static entry point handles installation
/// transparently.
class AppLifecycleObserver with WidgetsBindingObserver {
  final StreamController<AppLifecycleEvent> _controller =
      StreamController<AppLifecycleEvent>.broadcast();
  bool _attached = false;

  /// Broadcast stream of lifecycle events. Multiple wizard flows can
  /// subscribe simultaneously without colliding.
  Stream<AppLifecycleEvent> get stream => _controller.stream;

  /// Attach to the framework binding. No-op if already attached.
  void attach() {
    if (_attached) return;
    WidgetsBinding.instance.addObserver(this);
    _attached = true;
  }

  /// Detach from the framework binding. Mostly used by tests to clean up.
  void detach() {
    if (!_attached) return;
    WidgetsBinding.instance.removeObserver(this);
    _attached = false;
  }

  /// Force an event onto the stream. Used by tests; production code should
  /// rely on the platform driving [didChangeAppLifecycleState].
  @visibleForTesting
  void emit(AppLifecycleEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller.isClosed) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.add(AppLifecycleEvent.resumed);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.add(AppLifecycleEvent.backgrounded);
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// Disposes the underlying broadcast controller. Tests only.
  @visibleForTesting
  Future<void> dispose() async {
    detach();
    await _controller.close();
  }
}
