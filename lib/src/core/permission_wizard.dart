import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/batch_permission_request.dart';
import '../models/enums.dart';
import '../models/permission_rationale.dart';
import '../models/permission_request.dart';
import '../models/permission_wizard_callbacks.dart';
import '../models/permission_wizard_result.dart';
import '../platform/android_permission_checker.dart';
import '../platform/ios_permission_checker.dart';
import '../platform/platform_permission_checker.dart';
import '../ui/dialogs/rationale_dialog.dart';
import '../ui/sheets/rationale_bottom_sheet.dart';
import '../ui/screens/rationale_full_screen.dart';
import '../ui/widgets/wizard_theme_scope.dart';
import 'app_lifecycle_observer.dart';
import 'permission_cache.dart';
import 'request_queue.dart';
import 'settings_launcher.dart';
import 'wizard_session.dart';

/// Static entry point for the declarative permission flow.
///
/// Typical usage:
///
/// ```dart
/// final result = await PermissionWizard.request(
///   context: context,
///   request: PermissionRequest(
///     permission: Permission.camera,
///     rationale: PermissionRationale(
///       title: 'Camera Access',
///       description: 'Used to scan QR codes.',
///       allowButtonText: 'Allow',
///       denyButtonText: 'Not Now',
///     ),
///   ),
/// );
/// switch (result) {
///   case GrantedResult():   /* ... */ break;
///   case DeniedResult():    /* ... */ break;
///   case CancelledResult(): /* ... */ break;
///   case RestrictedResult(): /* ... */ break;
///   case LimitedResult():   /* ... */ break;
/// }
/// ```
///
/// The class is intentionally not instantiable — all entry points are
/// `static`. Internal collaborators (the platform checker, lifecycle
/// observer, etc.) can be overridden via [debugConfigure] in tests.
abstract final class PermissionWizard {
  PermissionWizard._();

  static PlatformPermissionChecker? _checkerOverride;
  static AppLifecycleObserver? _lifecycleOverride;
  static SettingsLauncher? _settingsOverride;
  static PermissionCache _cache = PermissionCache();
  static final RequestQueue _queue = RequestQueue();
  static AppLifecycleObserver? _ambientLifecycle;

  /// Replace internal collaborators. Used by tests and (rarely) by apps
  /// that want a custom settings landing page.
  @visibleForTesting
  static void debugConfigure({
    PlatformPermissionChecker? checker,
    AppLifecycleObserver? lifecycle,
    SettingsLauncher? settingsLauncher,
    PermissionCache? cache,
  }) {
    _checkerOverride = checker;
    _lifecycleOverride = lifecycle;
    _settingsOverride = settingsLauncher;
    if (cache != null) _cache = cache;
  }

  /// Reset to factory defaults. Tests should call this in tearDown to avoid
  /// state leaking between tests.
  @visibleForTesting
  static void debugReset() {
    _checkerOverride = null;
    _lifecycleOverride = null;
    _settingsOverride = null;
    _cache = PermissionCache();
    _ambientLifecycle?.detach();
    _ambientLifecycle = null;
    _queue.reset();
  }

  /// Internal helper exposed for the controller's standalone code path.
  /// Returns the same [PlatformPermissionChecker] that
  /// [PermissionWizard.request] would use, honouring any
  /// [debugConfigure]-installed override.
  static PlatformPermissionChecker resolveChecker() => _resolveChecker();

  /// Internal helper exposed for the controller's standalone code path.
  /// Returns the same [AppLifecycleObserver] that
  /// [PermissionWizard.request] would use, honouring any
  /// [debugConfigure]-installed override.
  static AppLifecycleObserver resolveLifecycle() => _resolveLifecycle();

  /// Internal helper exposed for the controller's standalone code path.
  static SettingsLauncher resolveSettingsLauncher() =>
      _resolveSettingsLauncher();

  /// Shared cache used by every wizard run. Tests can override via
  /// [debugConfigure] (which assigns a new instance).
  static PermissionCache get cache => _cache;

  static PlatformPermissionChecker _resolveChecker() {
    if (_checkerOverride != null) return _checkerOverride!;
    if (kIsWeb) return AndroidPermissionChecker();
    return Platform.isIOS
        ? IosPermissionChecker()
        : AndroidPermissionChecker();
  }

  static AppLifecycleObserver _resolveLifecycle() {
    if (_lifecycleOverride != null) return _lifecycleOverride!;
    _ambientLifecycle ??= AppLifecycleObserver()..attach();
    return _ambientLifecycle!;
  }

  static SettingsLauncher _resolveSettingsLauncher() {
    return _settingsOverride ?? const SettingsLauncher();
  }

  /// Run a single-permission wizard.
  ///
  /// Concurrent calls are queued automatically; at most one wizard is
  /// presented at a time.
  ///
  /// Any *unexpected* exception raised inside the wizard is intentionally
  /// trapped and surfaced as `CancelledResult(reason: 'internal_error')` —
  /// the wizard must never propagate an exception to the caller. The
  /// underlying error is sent through `FlutterError.reportError` so it
  /// surfaces in dev tooling.
  static Future<PermissionWizardResult> request({
    required BuildContext context,
    required PermissionRequest request,
  }) {
    return _queue.enqueue(() => _runSingle(context, request));
  }

  static Future<PermissionWizardResult> _runSingle(
    BuildContext context,
    PermissionRequest request,
  ) async {
    if (!context.mounted) {
      return const CancelledResult(
          reason: WizardCancelReason.appBackgrounded);
    }
    final session = WizardSession(
      request: request,
      checker: _resolveChecker(),
      cache: _cache,
      lifecycle: _resolveLifecycle(),
      settingsLauncher: _resolveSettingsLauncher(),
    );
    try {
      return await session.run(context);
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'flutter_permission_wizard',
        context: ErrorDescription(
          'while running PermissionWizard.request for ${request.permission}',
        ),
      ));
      return const CancelledResult(reason: WizardCancelReason.internalError);
    } finally {
      session.dispose();
    }
  }

  /// Run a batch wizard.
  ///
  /// See [BatchStrategy] for the two run modes. The returned
  /// [BatchPermissionWizardResult] indicates the outcome per permission as
  /// well as convenience getters such as `allGranted`.
  static Future<BatchPermissionWizardResult> requestBatch({
    required BuildContext context,
    required BatchPermissionRequest request,
  }) {
    return _queue.enqueue(() async {
      try {
        return await _runBatch(context, request);
      } catch (error, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'flutter_permission_wizard',
          context: ErrorDescription(
            'while running PermissionWizard.requestBatch',
          ),
        ));
        return BatchPermissionWizardResult({
          for (final entry in request.permissions)
            entry.permission: const CancelledResult(
                reason: WizardCancelReason.internalError),
        });
      }
    });
  }

  static Future<BatchPermissionWizardResult> _runBatch(
    BuildContext context,
    BatchPermissionRequest batch,
  ) async {
    if (batch.strategy == BatchStrategy.sequential) {
      final results = <Permission, PermissionWizardResult>{};
      for (final entry in batch.permissions) {
        if (!context.mounted) {
          results[entry.permission] = const CancelledResult(
              reason: WizardCancelReason.appBackgrounded);
          continue;
        }
        final session = WizardSession(
          request: entry,
          checker: _resolveChecker(),
          cache: _cache,
          lifecycle: _resolveLifecycle(),
          settingsLauncher: _resolveSettingsLauncher(),
        );
        try {
          results[entry.permission] = await session.run(context);
        } finally {
          session.dispose();
        }
      }
      return BatchPermissionWizardResult(results);
    }

    // Combined strategy.
    final checker = _resolveChecker();
    if (batch.skipIfAllGranted) {
      final statuses = <Permission, PermissionStatus>{};
      for (final entry in batch.permissions) {
        statuses[entry.permission] = await checker.status(entry.permission);
      }
      final allGranted = statuses.values.every(
        (s) => s.isGranted || s.isProvisional || s.isLimited,
      );
      if (allGranted) {
        return BatchPermissionWizardResult({
          for (final entry in statuses.entries)
            entry.key:
                entry.value.isLimited ? const LimitedResult() : const GrantedResult(),
        });
      }
    }

    if (!context.mounted) {
      return BatchPermissionWizardResult({
        for (final entry in batch.permissions)
          entry.permission: const CancelledResult(
              reason: WizardCancelReason.appBackgrounded),
      });
    }
    final accepted = batch.batchRationale == null
        ? true
        : await _showBatchRationale(context, batch.batchRationale!);
    if (!accepted) {
      return BatchPermissionWizardResult({
        for (final entry in batch.permissions)
          entry.permission: const CancelledResult(
              reason: WizardCancelReason.rationaleDismissed),
      });
    }

    // Sequential OS prompts using a rationale-less per-permission request.
    final results = <Permission, PermissionWizardResult>{};
    for (final entry in batch.permissions) {
      if (!context.mounted) {
        results[entry.permission] = const CancelledResult(
            reason: WizardCancelReason.appBackgrounded);
        continue;
      }
      final adapted = PermissionRequest(
        permission: entry.permission,
        rationale: null,
        deniedConfig: entry.deniedConfig,
        permanentlyDeniedConfig: entry.permanentlyDeniedConfig,
        restrictedConfig: entry.restrictedConfig,
        theme: entry.theme ?? batch.theme,
        callbacks: entry.callbacks ?? batch.callbacks,
        skipRationaleIfPreviouslyDenied: true,
        settingsReturnDelay: entry.settingsReturnDelay,
        maxRetryAttempts: entry.maxRetryAttempts,
      );
      final session = WizardSession(
        request: adapted,
        checker: checker,
        cache: _cache,
        lifecycle: _resolveLifecycle(),
        settingsLauncher: _resolveSettingsLauncher(),
      );
      try {
        results[entry.permission] = await session.run(context);
      } finally {
        session.dispose();
      }
    }
    return BatchPermissionWizardResult(results);
  }

  static Future<bool> _showBatchRationale(
    BuildContext context,
    PermissionRationale rationale,
  ) async {
    if (!context.mounted) return false;
    RationaleAction? result;
    switch (rationale.style) {
      case RationaleStyle.dialog:
        result = await showDialog<RationaleAction>(
          context: context,
          barrierDismissible: rationale.isDismissible,
          builder: (ctx) => _wrap(ctx, RationaleDialog(rationale: rationale)),
        );
        break;
      case RationaleStyle.bottomSheet:
        result = await showModalBottomSheet<RationaleAction>(
          context: context,
          isScrollControlled: true,
          isDismissible: rationale.isDismissible,
          enableDrag: rationale.isDismissible,
          backgroundColor: Colors.transparent,
          builder: (ctx) =>
              _wrap(ctx, RationaleBottomSheet(rationale: rationale)),
        );
        break;
      case RationaleStyle.fullScreen:
        result = await Navigator.of(context).push<RationaleAction>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (ctx) =>
                _wrap(ctx, RationaleFullScreen(rationale: rationale)),
          ),
        );
        break;
    }
    return result == RationaleAction.allow;
  }

  static Widget _wrap(BuildContext context, Widget child) =>
      WizardThemeScope(theme: WizardThemeScope.read(context), child: child);
}
