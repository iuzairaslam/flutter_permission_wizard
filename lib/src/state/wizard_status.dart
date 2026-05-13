/// High-level public status exposed by [PermissionWizardController] and
/// [PermissionWizardBuilder].
///
/// This is intentionally **coarser** than [WizardPhase] — consumers only need
/// to know whether the permission is currently granted, denied, restricted,
/// or being requested. Internal sub-states (such as "showing rationale") are
/// tracked separately by [PermissionStateMachine].
enum WizardStatus {
  /// Nothing has been done yet — call `request()` to start.
  initial,

  /// The status is being looked up.
  checking,

  /// The wizard is currently displaying UI (rationale, OS dialog, settings).
  inProgress,

  /// Permission is fully granted.
  granted,

  /// iOS Photos-style "selected items only" / limited grant.
  limited,

  /// Permission has been denied (soft or permanent — see
  /// [PermissionWizardController.isPermanentlyDenied] for the distinction).
  denied,

  /// The platform restricts the permission (MDM / parental controls).
  restricted,

  /// The wizard exited without a terminal grant/deny.
  cancelled,
}

/// Fine-grained internal phase used by [PermissionStateMachine] to drive
/// the UI. Exposed so tests and advanced consumers can introspect the flow
/// transition-by-transition.
enum WizardPhase {
  idle,
  checkingStatus,
  showingRationale,
  requestingOs,
  deniedSoft,
  deniedPermanent,
  openingSettings,
  awaitingResume,
  granted,
  limited,
  restricted,
  cancelled,
}
