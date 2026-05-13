import 'package:permission_handler/permission_handler.dart';

import 'platform_permission_checker.dart';

/// iOS-specific implementation of [PlatformPermissionChecker].
///
/// Behaviour notes:
///
/// * The very first denial on iOS is conceptually permanent — there is no
///   "ask again" affordance from the OS. We track whether the OS prompt has
///   been shown via [WizardPreferencesStorage]; once it has, any subsequent
///   denied status is mapped to [RequestOutcome.deniedPermanent].
/// * `Permission.photos` exposes the limited grant on iOS 14+, mapped to
///   [RequestOutcome.limited].
/// * `Permission.notification` is reported as `provisional` on iOS when the
///   user has only granted quiet delivery. We treat `provisional` as
///   granted because the app can still post notifications.
class IosPermissionChecker implements PlatformPermissionChecker {
  final WizardPreferencesStorage storage;

  IosPermissionChecker({WizardPreferencesStorage? storage})
      : storage = storage ?? InMemoryWizardStorage();

  @override
  bool get supportsLimited => true;

  @override
  Future<PermissionStatus> status(Permission permission) {
    return permission.status;
  }

  @override
  Future<RequestOutcome> request(Permission permission) async {
    final hasAsked = await hasBeenAskedBefore(permission);
    await markAsAsked(permission);
    final status = await permission.request();

    if (status.isGranted) return RequestOutcome.granted;
    if (status.isProvisional) return RequestOutcome.granted;
    if (status.isLimited) return RequestOutcome.limited;
    if (status.isRestricted) return RequestOutcome.restricted;
    if (status.isPermanentlyDenied) return RequestOutcome.deniedPermanent;

    // iOS: a `denied` after the prompt has been shown is effectively
    // permanent. Only the very first call (which the OS never actually
    // routes through the prompt because of restricted/etc reasons) can
    // legitimately return soft denial.
    if (status.isDenied && hasAsked) return RequestOutcome.deniedPermanent;
    return RequestOutcome.deniedPermanent;
  }

  @override
  Future<bool> canRequestAgain(Permission permission) async {
    final hasAsked = await hasBeenAskedBefore(permission);
    if (!hasAsked) return true;
    final status = await permission.status;
    if (status.isGranted ||
        status.isLimited ||
        status.isPermanentlyDenied ||
        status.isRestricted) {
      return false;
    }
    return false; // iOS: once asked, never auto-retryable.
  }

  @override
  Future<bool> hasBeenAskedBefore(Permission permission) =>
      storage.getBool(_storageKey(permission));

  @override
  Future<void> markAsAsked(Permission permission) =>
      storage.setBool(_storageKey(permission), true);

  String _storageKey(Permission permission) =>
      'flutter_permission_wizard:ios:${permission.value}';
}
