import 'package:permission_handler/permission_handler.dart';

import 'wizard_status.dart';

/// Inputs accepted by [PermissionStateMachine.transition]. Each value
/// represents a single observable event that can move the wizard from one
/// phase to another. Encoding inputs as an enum lets us validate
/// transitions exhaustively in tests.
enum WizardEvent {
  start,
  statusGranted,
  statusLimited,
  statusRestricted,
  needsRequest,
  rationaleAllow,
  rationaleDeny,
  osGranted,
  osLimited,
  osDeniedSoft,
  osDeniedPermanent,
  retry,
  openSettings,
  resumedFromSettings,
  skip,
  appBackgrounded,
}

/// Snapshot of the wizard at one point in time. Used as the immutable value
/// type stored in [PermissionStateMachine.history] for debug/testing.
class WizardSnapshot {
  final WizardPhase phase;
  final int retryCount;
  final bool hasOpenedSettings;
  final PermissionStatus? lastKnownStatus;

  const WizardSnapshot({
    required this.phase,
    required this.retryCount,
    required this.hasOpenedSettings,
    required this.lastKnownStatus,
  });

  @override
  String toString() =>
      'WizardSnapshot(phase: $phase, retries: $retryCount, settingsVisited: $hasOpenedSettings)';
}

/// Pure (UI-independent) finite-state machine that orchestrates a single
/// permission request from start to terminal state.
///
/// This class deliberately knows nothing about widgets, dialogs, or
/// `permission_handler`. It is fed [WizardEvent]s by the UI layer and emits
/// a new [phase] in response. Keeping the FSM platform-agnostic and side-
/// effect free lets us unit-test every transition deterministically.
class PermissionStateMachine {
  WizardPhase _phase = WizardPhase.idle;
  int _retryCount = 0;
  bool _hasOpenedSettings = false;
  PermissionStatus? _lastKnownStatus;
  final List<WizardSnapshot> history = [];

  /// Maximum number of *additional* retry rounds after the very first OS
  /// request.
  final int maxRetryAttempts;

  PermissionStateMachine({this.maxRetryAttempts = 1})
      : assert(maxRetryAttempts >= 0,
            'maxRetryAttempts must be non-negative.') {
    _snapshot();
  }

  WizardPhase get phase => _phase;
  int get retryCount => _retryCount;
  bool get hasOpenedSettings => _hasOpenedSettings;
  PermissionStatus? get lastKnownStatus => _lastKnownStatus;

  /// `true` once the machine has reached a phase that cannot transition
  /// further (granted, limited, restricted, cancelled, or permanent denial
  /// after the retry budget is exhausted).
  bool get isTerminal => switch (_phase) {
        WizardPhase.granted ||
        WizardPhase.limited ||
        WizardPhase.restricted ||
        WizardPhase.cancelled =>
          true,
        _ => false,
      };

  /// Feed the machine the latest `permission_handler` status without
  /// driving a transition. Useful when polling on app resume.
  void noteStatus(PermissionStatus status) {
    _lastKnownStatus = status;
  }

  /// Attempts to apply [event] to the current phase. Returns the new phase.
  ///
  /// Throws [StateError] when the event is invalid for the current phase —
  /// this surfaces UI bugs early during testing.
  WizardPhase transition(WizardEvent event) {
    final next = _resolveNext(event);
    if (next == null) {
      throw StateError(
        'Invalid wizard transition: cannot apply $event while in $_phase.',
      );
    }
    _phase = next;
    _snapshot();
    return _phase;
  }

  WizardPhase? _resolveNext(WizardEvent event) {
    switch (_phase) {
      case WizardPhase.idle:
        return event == WizardEvent.start ? WizardPhase.checkingStatus : null;

      case WizardPhase.checkingStatus:
        return switch (event) {
          WizardEvent.statusGranted => WizardPhase.granted,
          WizardEvent.statusLimited => WizardPhase.limited,
          WizardEvent.statusRestricted => WizardPhase.restricted,
          WizardEvent.needsRequest => _enterRequestFlow(),
          WizardEvent.appBackgrounded => WizardPhase.cancelled,
          _ => null,
        };

      case WizardPhase.showingRationale:
        return switch (event) {
          WizardEvent.rationaleAllow => WizardPhase.requestingOs,
          WizardEvent.rationaleDeny => WizardPhase.cancelled,
          WizardEvent.appBackgrounded => WizardPhase.cancelled,
          _ => null,
        };

      case WizardPhase.requestingOs:
        return switch (event) {
          WizardEvent.osGranted => WizardPhase.granted,
          WizardEvent.osLimited => WizardPhase.limited,
          WizardEvent.osDeniedSoft => _enterSoftDenial(),
          WizardEvent.osDeniedPermanent => WizardPhase.deniedPermanent,
          WizardEvent.statusRestricted => WizardPhase.restricted,
          _ => null,
        };

      case WizardPhase.deniedSoft:
        return switch (event) {
          WizardEvent.retry => _onRetry(),
          WizardEvent.skip => WizardPhase.cancelled,
          WizardEvent.appBackgrounded => WizardPhase.cancelled,
          _ => null,
        };

      case WizardPhase.deniedPermanent:
        return switch (event) {
          WizardEvent.openSettings => WizardPhase.openingSettings,
          WizardEvent.skip => WizardPhase.cancelled,
          WizardEvent.appBackgrounded => WizardPhase.cancelled,
          _ => null,
        };

      case WizardPhase.openingSettings:
        if (event == WizardEvent.appBackgrounded ||
            event == WizardEvent.openSettings) {
          _hasOpenedSettings = true;
          return WizardPhase.awaitingResume;
        }
        return null;

      case WizardPhase.awaitingResume:
        return switch (event) {
          WizardEvent.resumedFromSettings => WizardPhase.checkingStatus,
          WizardEvent.skip => WizardPhase.cancelled,
          WizardEvent.appBackgrounded => WizardPhase.cancelled,
          _ => null,
        };

      // Terminal phases — nothing accepted.
      case WizardPhase.granted:
      case WizardPhase.limited:
      case WizardPhase.restricted:
      case WizardPhase.cancelled:
        return null;
    }
  }

  WizardPhase _enterRequestFlow() {
    // Showing rationale is the default entry; the orchestrator can choose
    // to push `rationaleAllow` immediately if no rationale is configured,
    // which has the practical effect of jumping straight to `requestingOs`.
    return WizardPhase.showingRationale;
  }

  WizardPhase _enterSoftDenial() {
    if (_retryCount >= maxRetryAttempts) {
      // Retry budget exhausted → treat as terminal cancellation.
      return WizardPhase.cancelled;
    }
    return WizardPhase.deniedSoft;
  }

  WizardPhase _onRetry() {
    _retryCount += 1;
    return WizardPhase.showingRationale;
  }

  /// Direct setter so the orchestrator can fast-forward when the
  /// rationale step is disabled (e.g. when `rationale` is null or
  /// `skipRationaleIfPreviouslyDenied` is satisfied).
  void skipRationale() {
    if (_phase == WizardPhase.showingRationale) {
      _phase = WizardPhase.requestingOs;
      _snapshot();
    }
  }

  void _snapshot() {
    history.add(WizardSnapshot(
      phase: _phase,
      retryCount: _retryCount,
      hasOpenedSettings: _hasOpenedSettings,
      lastKnownStatus: _lastKnownStatus,
    ));
  }

  /// Map fine-grained [WizardPhase] to the coarser public [WizardStatus].
  static WizardStatus statusForPhase(WizardPhase phase) => switch (phase) {
        WizardPhase.idle => WizardStatus.initial,
        WizardPhase.checkingStatus => WizardStatus.checking,
        WizardPhase.granted => WizardStatus.granted,
        WizardPhase.limited => WizardStatus.limited,
        WizardPhase.restricted => WizardStatus.restricted,
        WizardPhase.cancelled => WizardStatus.cancelled,
        WizardPhase.deniedSoft ||
        WizardPhase.deniedPermanent =>
          WizardStatus.denied,
        WizardPhase.showingRationale ||
        WizardPhase.requestingOs ||
        WizardPhase.openingSettings ||
        WizardPhase.awaitingResume =>
          WizardStatus.inProgress,
      };
}
