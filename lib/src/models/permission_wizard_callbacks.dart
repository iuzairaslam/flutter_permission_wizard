import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Reason supplied to [PermissionWizardCallbacks.onCancelled].
///
/// Codified as constants (rather than an enum) so consumers can pipe them
/// straight into analytics tools as stable string identifiers.
abstract class WizardCancelReason {
  static const String rationaleDismissed = 'rationale_dismissed';
  static const String softDeniedSkipped = 'soft_denied_skipped';
  static const String permanentDeniedSkipped = 'permanent_denied_skipped';
  static const String maxRetriesExceeded = 'max_retries_exceeded';
  static const String appBackgrounded = 'app_backgrounded';
  static const String restrictedDismissed = 'restricted_dismissed';

  /// Wizard was explicitly cancelled by the host (e.g.
  /// [PermissionWizardController.cancel]).
  static const String cancelledByHost = 'cancelled_by_host';

  /// An unexpected exception was caught inside the wizard. The original
  /// error is reported via `FlutterError.reportError`. Should be treated
  /// as a denied permission from the user's perspective.
  static const String internalError = 'internal_error';
}

/// Pure analytics & side-effect hooks. None of these influence the flow —
/// they are *strictly* observational so consumers can wire up tracking
/// without affecting wizard behaviour.
@immutable
class PermissionWizardCallbacks {
  final VoidCallback? onRationaleShown;
  final VoidCallback? onRationaleAccepted;
  final VoidCallback? onRationaleDismissed;
  final VoidCallback? onOSDialogPresented;
  final VoidCallback? onGranted;

  /// Fired whenever the user ends in a denied state.
  /// [isPermanent] distinguishes Android soft denial (`false`) from
  /// permanent denial / iOS denial (`true`).
  final void Function(bool isPermanent)? onDenied;

  final VoidCallback? onRestricted;
  final VoidCallback? onSettingsOpened;
  final void Function(PermissionStatus statusAfterReturn)? onReturnedFromSettings;

  /// Fired when the wizard exits without resolving the permission.
  /// The supplied string is one of the [WizardCancelReason] constants.
  final void Function(String reason)? onCancelled;

  const PermissionWizardCallbacks({
    this.onRationaleShown,
    this.onRationaleAccepted,
    this.onRationaleDismissed,
    this.onOSDialogPresented,
    this.onGranted,
    this.onDenied,
    this.onRestricted,
    this.onSettingsOpened,
    this.onReturnedFromSettings,
    this.onCancelled,
  });
}
