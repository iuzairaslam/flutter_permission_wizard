import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/permission_request.dart';
import '../models/permission_wizard_callbacks.dart';
import '../models/permission_wizard_result.dart';
import '../platform/platform_permission_checker.dart';
import '../state/wizard_status.dart';
import 'app_lifecycle_observer.dart';
import 'permission_cache.dart';
import 'permission_wizard.dart';
import 'settings_launcher.dart';
import 'wizard_session.dart';

/// Stateful controller for advanced flows.
///
/// Three use cases this exists for:
///
/// 1. Triggering a wizard flow from outside a widget (e.g. from a Bloc).
/// 2. Driving multiple, interlocking wizards from a single owning class.
/// 3. Reactively rebuilding when the *current* status changes — the
///    controller is a [ChangeNotifier] and exposes [currentStatus] /
///    [stream].
///
/// The controller is a one-time-use lifecycle object: once [dispose] is
/// called it must not be re-used.
class PermissionWizardController extends ChangeNotifier {
  PermissionRequest request;

  WizardStatus _status = WizardStatus.initial;
  PermissionWizardResult? _lastResult;
  PermissionStatus? _lastPermissionStatus;
  bool _disposed = false;
  WizardSession? _activeSession;
  // Observer instances we created on behalf of an explicit-override flow.
  // These live for the lifetime of the controller and are detached in
  // [dispose].
  final List<AppLifecycleObserver> _ownedObservers = [];

  final StreamController<WizardStatus> _streamController =
      StreamController<WizardStatus>.broadcast();

  final PlatformPermissionChecker? checkerOverride;
  final AppLifecycleObserver? lifecycleOverride;
  final SettingsLauncher? settingsLauncherOverride;
  final PermissionCache? cacheOverride;

  PermissionWizardController({
    required this.request,
    this.checkerOverride,
    this.lifecycleOverride,
    this.settingsLauncherOverride,
    this.cacheOverride,
  });

  WizardStatus get currentStatus => _status;
  PermissionWizardResult? get lastResult => _lastResult;

  /// Broadcast stream of status changes. Multiple listeners are allowed.
  Stream<WizardStatus> get stream => _streamController.stream;

  bool get isPermanentlyDenied {
    final last = _lastResult;
    return last is DeniedResult && last.isPermanent;
  }

  bool get isGranted =>
      _status == WizardStatus.granted || _status == WizardStatus.limited;

  /// Whether a wizard run is currently in flight.
  bool get isBusy => _activeSession != null;

  /// Trigger or re-trigger the wizard. Stream listeners get every status
  /// change along the way; the returned future resolves with the terminal
  /// result.
  ///
  /// Concurrent calls share the global request queue used by
  /// [PermissionWizard.request]. If the controller is busy, calls are
  /// serialised.
  Future<PermissionWizardResult> requestPermission(BuildContext context) async {
    if (_disposed) {
      return const CancelledResult(
          reason: WizardCancelReason.cancelledByHost);
    }
    _emit(WizardStatus.checking);
    final result = await _runSession(context);
    if (_disposed) return result;
    _lastResult = result;
    _emit(switch (result) {
      GrantedResult() => WizardStatus.granted,
      LimitedResult() => WizardStatus.limited,
      DeniedResult() => WizardStatus.denied,
      RestrictedResult() => WizardStatus.restricted,
      CancelledResult() => WizardStatus.cancelled,
    });
    return result;
  }

  /// Refresh the cached permission status without prompting the user.
  Future<PermissionStatus> refreshStatus() async {
    final checker = checkerOverride ?? PermissionWizard.resolveChecker();
    final status = await checker.status(request.permission);
    if (_disposed) return status;
    _lastPermissionStatus = status;
    if (status.isGranted || status.isProvisional) {
      _emit(WizardStatus.granted);
    } else if (status.isLimited) {
      _emit(WizardStatus.limited);
    } else if (status.isRestricted) {
      _emit(WizardStatus.restricted);
    } else if (status.isPermanentlyDenied) {
      _emit(WizardStatus.denied);
    } else if (status.isDenied) {
      _emit(WizardStatus.denied);
    }
    return status;
  }

  PermissionStatus? get lastRawStatus => _lastPermissionStatus;

  /// Aborts an in-flight wizard, if any. The pending
  /// [requestPermission] future resolves with
  /// `CancelledResult(reason: 'cancelled_by_host')`.
  ///
  /// Safe to call even when [isBusy] is `false`.
  void cancel() {
    _activeSession?.cancel(WizardCancelReason.cancelledByHost);
  }

  Future<PermissionWizardResult> _runSession(BuildContext context) async {
    if (checkerOverride != null) {
      final lifecycle = lifecycleOverride ?? _spawnOwnedObserver();
      final session = WizardSession(
        request: request,
        checker: checkerOverride!,
        cache: cacheOverride ?? PermissionWizard.cache,
        lifecycle: lifecycle,
        settingsLauncher:
            settingsLauncherOverride ?? PermissionWizard.resolveSettingsLauncher(),
        onStatusChanged: _emit,
      );
      _activeSession = session;
      try {
        return await session.run(context);
      } catch (error, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'flutter_permission_wizard',
          context: ErrorDescription(
            'while running PermissionWizardController.requestPermission for '
            '${request.permission}',
          ),
        ));
        return const CancelledResult(
            reason: WizardCancelReason.internalError);
      } finally {
        session.dispose();
        _activeSession = null;
      }
    }
    // Without explicit overrides delegate to the shared
    // [PermissionWizard.request] which respects the global request queue
    // and any [debugConfigure]-installed fakes.
    return PermissionWizard.request(context: context, request: request);
  }

  AppLifecycleObserver _spawnOwnedObserver() {
    final observer = AppLifecycleObserver()..attach();
    _ownedObservers.add(observer);
    return observer;
  }

  void _emit(WizardStatus status) {
    if (_disposed) return;
    if (_status == status) return;
    _status = status;
    notifyListeners();
    if (!_streamController.isClosed) {
      _streamController.add(status);
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _activeSession?.cancel(WizardCancelReason.cancelledByHost);
    _activeSession = null;
    for (final obs in _ownedObservers) {
      obs.detach();
    }
    _ownedObservers.clear();
    if (!_streamController.isClosed) {
      _streamController.close();
    }
    super.dispose();
  }
}
