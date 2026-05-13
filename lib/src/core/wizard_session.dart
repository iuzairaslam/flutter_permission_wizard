import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/enums.dart';
import '../models/permission_denied_config.dart';
import '../models/permission_rationale.dart';
import '../models/permission_request.dart';
import '../models/permission_wizard_callbacks.dart';
import '../models/permission_wizard_result.dart';
import '../models/wizard_theme.dart';
import '../platform/platform_permission_checker.dart';
import '../state/permission_state_machine.dart';
import '../state/wizard_status.dart';
import '../ui/dialogs/denied_dialog.dart';
import '../ui/dialogs/rationale_dialog.dart';
import '../ui/screens/denied_full_screen.dart';
import '../ui/screens/rationale_full_screen.dart';
import '../ui/sheets/denied_bottom_sheet.dart';
import '../ui/sheets/rationale_bottom_sheet.dart';
import '../ui/widgets/wizard_theme_scope.dart';
import 'app_lifecycle_observer.dart';
import 'permission_cache.dart';
import 'settings_launcher.dart';

/// Callback wired up by [PermissionWizardController] so it can stream
/// status updates as the session progresses.
typedef WizardStatusListener = void Function(WizardStatus status);

enum _RationaleOutcome { allowed, dismissed, backgrounded }

enum _DeniedOutcome { openSettings, retry, skip, backgrounded }

enum _SoftDenialDecision { retry, skip, backgrounded }

/// Single-shot orchestrator for one wizard flow.
///
/// Wraps the pure FSM ([PermissionStateMachine]) with all the side-effects
/// it intentionally avoids: dialogs, the OS prompt, settings navigation,
/// lifecycle handling. Construct one instance per `request()` call —
/// instances are not reusable.
class WizardSession {
  final PermissionRequest request;
  final PlatformPermissionChecker checker;
  final PermissionCache cache;
  final AppLifecycleObserver lifecycle;
  final SettingsLauncher settingsLauncher;
  final WizardStatusListener? onStatusChanged;

  late final PermissionStateMachine _machine =
      PermissionStateMachine(maxRetryAttempts: request.maxRetryAttempts);

  StreamSubscription<AppLifecycleEvent>? _lifecycleSub;
  StreamSubscription<AppLifecycleEvent>? _settingsResumeSub;
  Completer<void>? _settingsResumeCompleter;
  bool _backgroundedDuringDialog = false;
  bool _dialogOpen = false;
  bool _settingsRoundTripDone = false;
  bool _disposed = false;
  bool _cancelled = false;
  String _cancelReason = WizardCancelReason.cancelledByHost;
  NavigatorState? _navigatorForDismiss;

  WizardSession({
    required this.request,
    required this.checker,
    required this.cache,
    required this.lifecycle,
    required this.settingsLauncher,
    this.onStatusChanged,
  });

  /// Whether this session has been cancelled (by [cancel] or [dispose]).
  bool get isCancelled => _cancelled;

  /// Drives the entire flow and returns a sealed [PermissionWizardResult].
  Future<PermissionWizardResult> run(BuildContext context) async {
    if (_disposed) {
      return const CancelledResult(
          reason: WizardCancelReason.cancelledByHost);
    }
    _emitStatus();
    _machine.transition(WizardEvent.start);
    _emitStatus();

    if (_cancelled) return _cancelResult();
    final initial = await _readStatus();
    if (_cancelled) return _cancelResult();
    _machine.noteStatus(initial);

    if (initial.isGranted || initial.isProvisional) {
      _machine.transition(WizardEvent.statusGranted);
      _fire(() => request.callbacks?.onGranted?.call());
      _emitStatus();
      return const GrantedResult();
    }
    if (initial.isLimited) {
      _machine.transition(WizardEvent.statusLimited);
      _fire(() => request.callbacks?.onGranted?.call());
      _emitStatus();
      return const LimitedResult();
    }
    if (initial.isRestricted) {
      _machine.transition(WizardEvent.statusRestricted);
      _fire(() => request.callbacks?.onRestricted?.call());
      _emitStatus();
      return const RestrictedResult();
    }
    if (initial.isPermanentlyDenied) {
      _machine.transition(WizardEvent.needsRequest);
      _machine.skipRationale();
      _machine.transition(WizardEvent.osDeniedPermanent);
      _fire(() => request.callbacks?.onDenied?.call(true));
      _emitStatus();
      if (!context.mounted) return const DeniedResult(isPermanent: true);
      return _resolvePermanentDenial(context);
    }

    _machine.transition(WizardEvent.needsRequest);
    _emitStatus();

    final hasAskedBefore = await checker.hasBeenAskedBefore(request.permission);
    final shouldShowRationale = request.rationale != null &&
        !(request.skipRationaleIfPreviouslyDenied && hasAskedBefore);

    if (shouldShowRationale) {
      if (!context.mounted) {
        return const CancelledResult(
            reason: WizardCancelReason.appBackgrounded);
      }
      if (_cancelled) return _cancelResult();
      final outcome = await _showRationale(context, request.rationale!);
      if (_cancelled) return _cancelResult();
      if (outcome == _RationaleOutcome.dismissed) {
        _machine.transition(WizardEvent.rationaleDeny);
        _emitStatus();
        _fire(() => request.callbacks?.onRationaleDismissed?.call());
        _fire(() => request.callbacks
            ?.onCancelled
            ?.call(WizardCancelReason.rationaleDismissed));
        return const CancelledResult(
            reason: WizardCancelReason.rationaleDismissed);
      }
      if (outcome == _RationaleOutcome.backgrounded) {
        _machine.transition(WizardEvent.appBackgrounded);
        _emitStatus();
        _fire(() => request.callbacks
            ?.onCancelled
            ?.call(WizardCancelReason.appBackgrounded));
        return const CancelledResult(reason: WizardCancelReason.appBackgrounded);
      }
      _fire(() => request.callbacks?.onRationaleAccepted?.call());
      _machine.transition(WizardEvent.rationaleAllow);
    } else {
      _machine.skipRationale();
    }
    _emitStatus();

    if (!context.mounted) {
      return const CancelledResult(reason: WizardCancelReason.appBackgrounded);
    }
    return _runOsRequestLoop(context);
  }

  Future<PermissionWizardResult> _runOsRequestLoop(
      BuildContext context) async {
    while (true) {
      if (_cancelled) return _cancelResult();
      _fire(() => request.callbacks?.onOSDialogPresented?.call());
      final outcome = await checker.request(request.permission);
      cache.invalidate(request.permission);
      if (_cancelled) return _cancelResult();
      switch (outcome) {
        case RequestOutcome.granted:
          _machine.transition(WizardEvent.osGranted);
          _fire(() => request.callbacks?.onGranted?.call());
          _emitStatus();
          return const GrantedResult();

        case RequestOutcome.limited:
          _machine.transition(WizardEvent.osLimited);
          _fire(() => request.callbacks?.onGranted?.call());
          _emitStatus();
          return const LimitedResult();

        case RequestOutcome.restricted:
          _machine.transition(WizardEvent.statusRestricted);
          _fire(() => request.callbacks?.onRestricted?.call());
          _emitStatus();
          return const RestrictedResult();

        case RequestOutcome.deniedSoft:
          final newPhase = _machine.transition(WizardEvent.osDeniedSoft);
          _emitStatus();
          if (newPhase == WizardPhase.cancelled) {
            _fire(() => request.callbacks?.onDenied?.call(false));
            _fire(() => request.callbacks
                ?.onCancelled
                ?.call(WizardCancelReason.maxRetriesExceeded));
            return const CancelledResult(
                reason: WizardCancelReason.maxRetriesExceeded);
          }
          _fire(() => request.callbacks?.onDenied?.call(false));
          if (!context.mounted) {
            return const CancelledResult(
                reason: WizardCancelReason.appBackgrounded);
          }
          final decision = await _resolveSoftDenial(context);
          switch (decision) {
            case _SoftDenialDecision.retry:
              // Retry has already transitioned the FSM to showingRationale;
              // fast-forward to requestingOs without rendering the
              // rationale a second time. Showing the same dialog twice is
              // bad UX (the user already saw it once during this run).
              _machine.skipRationale();
              continue;
            case _SoftDenialDecision.skip:
              _fire(() => request.callbacks
                  ?.onCancelled
                  ?.call(WizardCancelReason.softDeniedSkipped));
              return const DeniedResult(isPermanent: false);
            case _SoftDenialDecision.backgrounded:
              _fire(() => request.callbacks
                  ?.onCancelled
                  ?.call(WizardCancelReason.appBackgrounded));
              return const CancelledResult(
                  reason: WizardCancelReason.appBackgrounded);
          }

        case RequestOutcome.deniedPermanent:
          _machine.transition(WizardEvent.osDeniedPermanent);
          _fire(() => request.callbacks?.onDenied?.call(true));
          _emitStatus();
          if (!context.mounted) return const DeniedResult(isPermanent: true);
          return _resolvePermanentDenial(context);
      }
    }
  }

  Future<_SoftDenialDecision> _resolveSoftDenial(BuildContext context) async {
    final config = request.deniedConfig ??
        const PermissionDeniedConfig(
          title: 'Permission Needed',
          description:
              'We still need this permission to continue. Tap try again to grant it.',
          retryText: 'Try Again',
          skipText: 'Skip',
        );
    final action =
        await _showDenied(context, config, suppressOpenSettings: true);
    if (action == _DeniedOutcome.retry) {
      _machine.transition(WizardEvent.retry);
      _emitStatus();
      return _SoftDenialDecision.retry;
    }
    if (action == _DeniedOutcome.backgrounded) {
      _machine.transition(WizardEvent.appBackgrounded);
      _emitStatus();
      return _SoftDenialDecision.backgrounded;
    }
    _machine.transition(WizardEvent.skip);
    _emitStatus();
    return _SoftDenialDecision.skip;
  }

  Future<PermissionWizardResult> _resolvePermanentDenial(
    BuildContext context,
  ) async {
    final config = request.permanentlyDeniedConfig ??
        request.deniedConfig ??
        const PermissionDeniedConfig(
          title: 'Permission Blocked',
          description:
              'This permission has been turned off. To use this feature, '
                  'open settings and enable it.',
          openSettingsText: 'Open Settings',
          skipText: 'Skip',
        );

    final action = await _showDenied(
      context,
      config,
      suppressOpenSettings: _settingsRoundTripDone,
    );

    if (action == _DeniedOutcome.openSettings) {
      _machine.transition(WizardEvent.openSettings);
      _emitStatus();
      _fire(() => request.callbacks?.onSettingsOpened?.call());
      if (!context.mounted) return const DeniedResult(isPermanent: true);
      return _awaitSettingsRoundTrip(context);
    }
    if (action == _DeniedOutcome.backgrounded) {
      _machine.transition(WizardEvent.appBackgrounded);
      _emitStatus();
      _fire(() => request.callbacks
          ?.onCancelled
          ?.call(WizardCancelReason.appBackgrounded));
      return const CancelledResult(reason: WizardCancelReason.appBackgrounded);
    }
    _machine.transition(WizardEvent.skip);
    _emitStatus();
    _fire(() => request.callbacks
        ?.onCancelled
        ?.call(WizardCancelReason.permanentDeniedSkipped));
    return const DeniedResult(isPermanent: true);
  }

  Future<PermissionWizardResult> _awaitSettingsRoundTrip(
      BuildContext context) async {
    // Trigger the FSM bridge transition: openingSettings → awaitingResume.
    // This re-uses the existing `openSettings` arrow which conveniently sets
    // `hasOpenedSettings` at the same time.
    _machine.transition(WizardEvent.openSettings);
    _emitStatus();
    final completer = Completer<void>();
    _settingsResumeCompleter = completer;
    // Broadcast streams only deliver events that fire *after* the
    // listener attaches, so wire the listener up *before* triggering the
    // launcher. The very first resume event after that point is treated
    // as the user coming back from Settings.
    StreamSubscription<AppLifecycleEvent>? sub;
    sub = lifecycle.stream.listen((event) {
      if (event == AppLifecycleEvent.resumed && !completer.isCompleted) {
        completer.complete();
        sub?.cancel();
      }
    });
    _settingsResumeSub = sub;

    // Trigger the launcher fire-and-forget so we don't block waiting for
    // the platform channel to acknowledge the intent. We still surface
    // launcher exceptions via FlutterError so failures don't disappear.
    unawaited(_safeLaunchSettings());

    await completer.future;
    _settingsResumeSub = null;
    _settingsResumeCompleter = null;
    if (_cancelled) return _cancelResult();

    await Future<void>.delayed(request.settingsReturnDelay);
    if (_cancelled) return _cancelResult();

    _settingsRoundTripDone = true;
    final newStatus = await _readStatus(forceRefresh: true);
    _machine.noteStatus(newStatus);
    _machine.transition(WizardEvent.resumedFromSettings);
    _emitStatus();
    _fire(() => request.callbacks?.onReturnedFromSettings?.call(newStatus));

    if (newStatus.isGranted || newStatus.isProvisional) {
      _machine.transition(WizardEvent.statusGranted);
      _fire(() => request.callbacks?.onGranted?.call());
      _emitStatus();
      return const GrantedResult();
    }
    if (newStatus.isLimited) {
      _machine.transition(WizardEvent.statusLimited);
      _fire(() => request.callbacks?.onGranted?.call());
      _emitStatus();
      return const LimitedResult();
    }
    if (newStatus.isRestricted) {
      _machine.transition(WizardEvent.statusRestricted);
      _fire(() => request.callbacks?.onRestricted?.call());
      _emitStatus();
      return const RestrictedResult();
    }
    if (!context.mounted) {
      return const DeniedResult(isPermanent: true);
    }
    // Round-trip yielded nothing → re-enter the permanent denied screen,
    // this time with `suppressOpenSettings` set to true via the flag.
    _machine.transition(WizardEvent.needsRequest);
    _machine.skipRationale();
    _machine.transition(WizardEvent.osDeniedPermanent);
    _emitStatus();
    return _resolvePermanentDenial(context);
  }

  // ---------------------------------------------------------------------------
  // UI presentation helpers
  // ---------------------------------------------------------------------------

  Future<_RationaleOutcome> _showRationale(
    BuildContext context,
    PermissionRationale rationale,
  ) async {
    if (!context.mounted) return _RationaleOutcome.dismissed;
    _fire(() => request.callbacks?.onRationaleShown?.call());

    _navigatorForDismiss = Navigator.of(context);
    _attachLifecycle();

    RationaleAction? result;
    if (rationale.customBuilder != null) {
      _dialogOpen = true;
      result = await Navigator.of(context).push<RationaleAction>(
        PageRouteBuilder<RationaleAction>(
          opaque: false,
          fullscreenDialog: true,
          pageBuilder: (ctx, _, __) => _wrapWithTheme(
            ctx,
            rationale.customBuilder!(
              ctx,
              () => Navigator.of(ctx).pop(RationaleAction.allow),
              () => Navigator.of(ctx).pop(RationaleAction.deny),
            ),
          ),
        ),
      );
      _dialogOpen = false;
    } else {
      switch (rationale.style) {
        case RationaleStyle.dialog:
          _dialogOpen = true;
          result = await showDialog<RationaleAction>(
            context: context,
            barrierDismissible: rationale.isDismissible,
            builder: (ctx) => _wrapWithTheme(
              ctx,
              RationaleDialog(rationale: rationale),
            ),
          );
          _dialogOpen = false;
          break;
        case RationaleStyle.bottomSheet:
          _dialogOpen = true;
          result = await showModalBottomSheet<RationaleAction>(
            context: context,
            isScrollControlled: true,
            isDismissible: rationale.isDismissible,
            enableDrag: rationale.isDismissible,
            backgroundColor: Colors.transparent,
            builder: (ctx) => _wrapWithTheme(
              ctx,
              RationaleBottomSheet(rationale: rationale),
            ),
          );
          _dialogOpen = false;
          break;
        case RationaleStyle.fullScreen:
          _dialogOpen = true;
          result = await Navigator.of(context).push<RationaleAction>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (ctx) => _wrapWithTheme(
                ctx,
                RationaleFullScreen(rationale: rationale),
              ),
            ),
          );
          _dialogOpen = false;
          break;
      }
    }

    final wasBackgrounded = _backgroundedDuringDialog;
    _backgroundedDuringDialog = false;
    _detachLifecycle();

    if (wasBackgrounded) return _RationaleOutcome.backgrounded;
    return switch (result) {
      RationaleAction.allow => _RationaleOutcome.allowed,
      RationaleAction.deny => _RationaleOutcome.dismissed,
      null => _RationaleOutcome.dismissed,
    };
  }

  Future<_DeniedOutcome> _showDenied(
    BuildContext context,
    PermissionDeniedConfig config, {
    bool suppressOpenSettings = false,
  }) async {
    if (!context.mounted) return _DeniedOutcome.skip;

    _navigatorForDismiss = Navigator.of(context);
    _attachLifecycle();

    DeniedAction? result;
    if (config.customBuilder != null) {
      _dialogOpen = true;
      result = await Navigator.of(context).push<DeniedAction>(
        PageRouteBuilder<DeniedAction>(
          opaque: false,
          fullscreenDialog: true,
          pageBuilder: (ctx, _, __) => _wrapWithTheme(
            ctx,
            config.customBuilder!(
              ctx,
              config.openSettingsText != null && !suppressOpenSettings
                  ? () => Navigator.of(ctx).pop(DeniedAction.openSettings)
                  : null,
              config.retryText != null
                  ? () => Navigator.of(ctx).pop(DeniedAction.retry)
                  : null,
              () => Navigator.of(ctx).pop(DeniedAction.skip),
            ),
          ),
        ),
      );
      _dialogOpen = false;
    } else {
      switch (config.style) {
        case DeniedStyle.dialog:
          _dialogOpen = true;
          result = await showDialog<DeniedAction>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => _wrapWithTheme(
              ctx,
              DeniedDialog(
                config: config,
                suppressOpenSettings: suppressOpenSettings,
              ),
            ),
          );
          _dialogOpen = false;
          break;
        case DeniedStyle.bottomSheet:
          _dialogOpen = true;
          result = await showModalBottomSheet<DeniedAction>(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => _wrapWithTheme(
              ctx,
              DeniedBottomSheet(
                config: config,
                suppressOpenSettings: suppressOpenSettings,
              ),
            ),
          );
          _dialogOpen = false;
          break;
        case DeniedStyle.fullScreen:
          _dialogOpen = true;
          result = await Navigator.of(context).push<DeniedAction>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (ctx) => _wrapWithTheme(
                ctx,
                DeniedFullScreen(
                  config: config,
                  suppressOpenSettings: suppressOpenSettings,
                ),
              ),
            ),
          );
          _dialogOpen = false;
          break;
      }
    }

    final wasBackgrounded = _backgroundedDuringDialog;
    _backgroundedDuringDialog = false;
    _detachLifecycle();

    if (wasBackgrounded) return _DeniedOutcome.backgrounded;
    return switch (result) {
      DeniedAction.openSettings => _DeniedOutcome.openSettings,
      DeniedAction.retry => _DeniedOutcome.retry,
      DeniedAction.skip => _DeniedOutcome.skip,
      null => _DeniedOutcome.skip,
    };
  }

  Widget _wrapWithTheme(BuildContext context, Widget child) {
    final theme = request.theme ?? WizardThemeScope.read(context);
    return WizardThemeScope(theme: theme, child: child);
  }

  void _attachLifecycle() {
    _lifecycleSub?.cancel();
    _lifecycleSub = lifecycle.stream.listen((event) {
      if (event == AppLifecycleEvent.backgrounded &&
          _dialogOpen &&
          !_backgroundedDuringDialog) {
        _backgroundedDuringDialog = true;
        final nav = _navigatorForDismiss;
        if (nav != null && nav.canPop()) {
          nav.pop();
        }
      }
    });
  }

  void _detachLifecycle() {
    _lifecycleSub?.cancel();
    _lifecycleSub = null;
  }

  Future<PermissionStatus> _readStatus({bool forceRefresh = false}) {
    if (forceRefresh) cache.invalidate(request.permission);
    return cache.readOrFetch(
      request.permission,
      () => checker.status(request.permission),
    );
  }

  void _emitStatus() {
    if (_disposed) return;
    onStatusChanged
        ?.call(PermissionStateMachine.statusForPhase(_machine.phase));
  }

  Future<void> _safeLaunchSettings() async {
    try {
      await settingsLauncher.open();
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'flutter_permission_wizard',
        context: ErrorDescription('while opening application settings'),
      ));
      // Synthesise a resume so the waiter unwinds — otherwise we'd hang
      // forever waiting for a return that can never happen.
      final pending = _settingsResumeCompleter;
      if (pending != null && !pending.isCompleted) {
        pending.complete();
      }
    }
  }

  /// Invoke a host-supplied callback while swallowing exceptions so a
  /// faulty analytics integration cannot break the wizard.
  ///
  /// Errors are intentionally silenced rather than reported via
  /// `FlutterError.reportError` because analytics integrations are
  /// allowed to be unreliable; raising them as framework errors would
  /// surface as red-screen test failures in apps that wire up tracking.
  /// Hosts that need visibility into callback failures should add their
  /// own try/catch inside the callback body.
  ///
  /// Hosts that wire up async work inside a callback should wrap it in
  /// `unawaited(...)` themselves — the wizard does not await callback
  /// futures.
  void _fire(void Function() fn) {
    try {
      fn();
    } catch (_) {
      // Intentionally swallowed — see docs above.
    }
  }

  /// Aborts the session. The in-flight `run` returns a
  /// [CancelledResult] with [reason]. Idempotent and safe to call from
  /// any state.
  void cancel([String reason = WizardCancelReason.cancelledByHost]) {
    if (_cancelled) return;
    _cancelled = true;
    _cancelReason = reason;
    // Pop the dialog so the awaiting Future resolves with `null`.
    final nav = _navigatorForDismiss;
    if (_dialogOpen && nav != null && nav.canPop()) {
      try {
        nav.pop();
      } catch (_) {
        // Navigator may have been disposed concurrently.
      }
    }
    // Complete any pending settings round-trip waiter so the run can
    // unwind.
    final pending = _settingsResumeCompleter;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
  }

  CancelledResult _cancelResult() => CancelledResult(reason: _cancelReason);

  /// Tear down lifecycle subscriptions. Always invoked from the orchestrator's
  /// `finally` block once the run finishes. Idempotent.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancel();
    _lifecycleSub?.cancel();
    _lifecycleSub = null;
    _settingsResumeSub?.cancel();
    _settingsResumeSub = null;
    _navigatorForDismiss = null;
  }

  @visibleForTesting
  PermissionStateMachine get machine => _machine;
}

/// Public re-exports so tests can reach the internal types if needed.
WizardTheme defaultWizardTheme() => const WizardTheme();
