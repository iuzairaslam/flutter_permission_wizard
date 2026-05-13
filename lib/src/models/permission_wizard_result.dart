import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sealed return type of [PermissionWizard.request].
///
/// Using a sealed class forces every caller to handle every case via a
/// pattern-matching `switch` — there is no way to forget the
/// "restricted" or "cancelled" path at compile time.
sealed class PermissionWizardResult {
  const PermissionWizardResult();
}

/// Permission was granted by the user or was already granted.
final class GrantedResult extends PermissionWizardResult {
  const GrantedResult();

  @override
  bool operator ==(Object other) => other is GrantedResult;
  @override
  int get hashCode => (GrantedResult).hashCode;
}

/// Permission was denied. [isPermanent] is `true` on iOS (after first
/// denial) and on Android when the user has checked "Don't ask again", or
/// when the wizard has exhausted its retry budget without a grant.
final class DeniedResult extends PermissionWizardResult {
  final bool isPermanent;
  const DeniedResult({required this.isPermanent});

  @override
  bool operator ==(Object other) =>
      other is DeniedResult && other.isPermanent == isPermanent;
  @override
  int get hashCode => Object.hash(DeniedResult, isPermanent);
}

/// Reported only for `Permission.photos` on iOS 14+ when the user picks the
/// "limited photo library" option. The wizard surfaces this as a dedicated
/// case so callers can offer a "Select More Photos" action without having
/// to special-case the `PermissionStatus` enum themselves.
final class LimitedResult extends PermissionWizardResult {
  const LimitedResult();

  @override
  bool operator ==(Object other) => other is LimitedResult;
  @override
  int get hashCode => (LimitedResult).hashCode;
}

/// MDM / parental controls block the permission — the user cannot grant it.
final class RestrictedResult extends PermissionWizardResult {
  const RestrictedResult();

  @override
  bool operator ==(Object other) => other is RestrictedResult;
  @override
  int get hashCode => (RestrictedResult).hashCode;
}

/// The user (or the framework) abandoned the wizard before reaching a
/// terminal grant/deny state. See [WizardCancelReason] for valid values.
final class CancelledResult extends PermissionWizardResult {
  final String reason;
  const CancelledResult({required this.reason});

  @override
  bool operator ==(Object other) =>
      other is CancelledResult && other.reason == reason;
  @override
  int get hashCode => Object.hash(CancelledResult, reason);
}

/// Aggregated result returned by [PermissionWizard.requestBatch].
@immutable
class BatchPermissionWizardResult {
  /// Result keyed by the original [Permission] requested.
  final Map<Permission, PermissionWizardResult> results;

  const BatchPermissionWizardResult(this.results);

  /// `true` when every permission resolved to [GrantedResult] or
  /// [LimitedResult].
  bool get allGranted => results.values.every(
        (r) => r is GrantedResult || r is LimitedResult,
      );

  /// `true` when at least one permission resolved to [GrantedResult] or
  /// [LimitedResult].
  bool get anyGranted => results.values.any(
        (r) => r is GrantedResult || r is LimitedResult,
      );

  /// List of permissions that ended up granted (or limited).
  List<Permission> get grantedPermissions => results.entries
      .where((e) => e.value is GrantedResult || e.value is LimitedResult)
      .map((e) => e.key)
      .toList(growable: false);

  /// List of permissions that ended up denied.
  List<Permission> get deniedPermissions => results.entries
      .where((e) => e.value is DeniedResult)
      .map((e) => e.key)
      .toList(growable: false);
}
