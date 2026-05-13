import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_denied_config.dart';
import 'permission_rationale.dart';
import 'permission_restricted_config.dart';
import 'permission_wizard_callbacks.dart';
import 'wizard_theme.dart';

/// Top-level configuration object describing exactly *one* permission flow
/// from rationale through to settings-return.
///
/// `PermissionRequest` is fully immutable and safe to declare as a `const`
/// constant when every field allows it. Pass it to
/// [PermissionWizard.request], [PermissionWizardBuilder] or
/// [PermissionWizardController] — those three entry points all consume the
/// same configuration object.
@immutable
class PermissionRequest {
  /// The `permission_handler` permission being requested.
  ///
  /// NOTE on Android 13+ image/audio: pass `Permission.photos`,
  /// `Permission.videos` or `Permission.audio` explicitly — the package
  /// purposefully does **not** translate these from `Permission.storage`.
  final Permission permission;

  /// Optional pre-OS-prompt explainer. When `null` the wizard skips straight
  /// to the OS request — only do that for permissions where context is
  /// already obvious from the surrounding UI.
  final PermissionRationale? rationale;

  /// Content for Android soft-denial (`shouldShowRequestPermissionRationale`
  /// returned `true`).
  final PermissionDeniedConfig? deniedConfig;

  /// Content for permanent denial (iOS, or Android "don't ask again").
  final PermissionDeniedConfig? permanentlyDeniedConfig;

  /// Content for the OS-reported restricted state (MDM / parental controls).
  final PermissionRestrictedConfig? restrictedConfig;

  /// Wizard-wide visual overrides. Falls back to the ambient `ThemeData`.
  final WizardTheme? theme;

  /// Analytics / observer hooks.
  final PermissionWizardCallbacks? callbacks;

  /// When `true` and the wizard detects this user has been through the flow
  /// before (i.e. the OS already denied the permission once), the rationale
  /// dialog is skipped to avoid nagging. Default `true`.
  final bool skipRationaleIfPreviouslyDenied;

  /// Delay applied after the app resumes from Settings before re-checking
  /// the permission status. Tunes around an Android quirk where the
  /// permission API sometimes lags behind the user's choice.
  /// Default `300ms`.
  final Duration settingsReturnDelay;

  /// Maximum number of *additional* retry rounds after the very first OS
  /// request. Default `1` — i.e. one retry of the rationale + OS request
  /// after a soft denial.
  final int maxRetryAttempts;

  const PermissionRequest({
    required this.permission,
    this.rationale,
    this.deniedConfig,
    this.permanentlyDeniedConfig,
    this.restrictedConfig,
    this.theme,
    this.callbacks,
    this.skipRationaleIfPreviouslyDenied = true,
    this.settingsReturnDelay = const Duration(milliseconds: 300),
    this.maxRetryAttempts = 1,
  }) : assert(
          maxRetryAttempts >= 0,
          'maxRetryAttempts must be non-negative (0 disables retry).',
        );
}
