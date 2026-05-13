import 'package:permission_handler/permission_handler.dart';

import 'platform_permission_checker.dart';

/// Android-specific implementation of [PlatformPermissionChecker].
///
/// Behaviour notes:
///
/// * The Android OS distinguishes "soft" denial (`PermissionStatus.denied`)
///   from "don't ask again" (`PermissionStatus.permanentlyDenied`). We map
///   directly to [RequestOutcome.deniedSoft] / [RequestOutcome.deniedPermanent].
/// * `shouldShowRequestRationale` further disambiguates the two in older
///   plugin versions where soft and permanent share a status code; we use
///   it as a defensive secondary check.
/// * `Permission.locationAlways` is documented to require a prior grant of
///   `Permission.locationWhenInUse` on Android 12+. The plugin chains this
///   automatically, so no extra work is needed here.
class AndroidPermissionChecker implements PlatformPermissionChecker {
  final WizardPreferencesStorage storage;

  AndroidPermissionChecker({WizardPreferencesStorage? storage})
      : storage = storage ?? InMemoryWizardStorage();

  @override
  bool get supportsLimited => false;

  @override
  Future<PermissionStatus> status(Permission permission) {
    return permission.status;
  }

  @override
  Future<RequestOutcome> request(Permission permission) async {
    await markAsAsked(permission);
    final status = await permission.request();
    if (status.isGranted) return RequestOutcome.granted;
    if (status.isLimited) return RequestOutcome.limited;
    if (status.isRestricted) return RequestOutcome.restricted;
    if (status.isPermanentlyDenied) return RequestOutcome.deniedPermanent;

    // Soft-denial detection — on Android 12 a single rejection still
    // returns `denied` not `permanentlyDenied`. Use the OS rationale flag
    // as the disambiguator: if the OS thinks we *should* show rationale,
    // we can ask again → soft. Otherwise treat as permanent.
    final canRetry = await permission.shouldShowRequestRationale;
    return canRetry ? RequestOutcome.deniedSoft : RequestOutcome.deniedPermanent;
  }

  @override
  Future<bool> canRequestAgain(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return false;
    if (status.isPermanentlyDenied || status.isRestricted) return false;
    return true;
  }

  @override
  Future<bool> hasBeenAskedBefore(Permission permission) =>
      storage.getBool(_storageKey(permission));

  @override
  Future<void> markAsAsked(Permission permission) =>
      storage.setBool(_storageKey(permission), true);

  String _storageKey(Permission permission) =>
      'flutter_permission_wizard:android:${permission.value}';
}
