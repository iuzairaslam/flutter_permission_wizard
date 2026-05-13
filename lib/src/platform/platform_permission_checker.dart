import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Outcome of a single call to [PlatformPermissionChecker.request], encoded
/// with enough resolution for the state machine to pick the right next
/// phase.
enum RequestOutcome {
  granted,
  limited,
  deniedSoft,
  deniedPermanent,
  restricted,
}

/// Platform-agnostic abstraction around `permission_handler`.
///
/// The concrete iOS and Android implementations encapsulate the subtle
/// behavioural differences between the two platforms (see class-level docs
/// on each subclass). The state machine and UI layers consume only this
/// interface and remain platform-agnostic.
abstract class PlatformPermissionChecker {
  /// Returns the current [PermissionStatus] without prompting the user.
  Future<PermissionStatus> status(Permission permission);

  /// Triggers the OS permission dialog and returns a classified outcome.
  ///
  /// Note that on iOS the very first denial is always permanent — the
  /// concrete iOS implementation handles this internally so callers do not
  /// have to.
  Future<RequestOutcome> request(Permission permission);

  /// `true` when the platform considers it safe to call
  /// [request] a second time. Always `false` on iOS once denied once.
  Future<bool> canRequestAgain(Permission permission);

  /// Has this permission ever been presented to the OS dialog before?
  /// Used by iOS to distinguish "first denial" (which is technically not
  /// permanent but practically equivalent) from "subsequent denial".
  Future<bool> hasBeenAskedBefore(Permission permission);

  /// Mark the permission as having been presented to the OS dialog.
  /// Called automatically by [request].
  Future<void> markAsAsked(Permission permission);

  /// Whether the running platform reports a "limited" status (only Photos
  /// on iOS 14+).
  bool get supportsLimited;
}

/// Minimal storage interface allowing the package to remember whether the
/// OS dialog has been presented before. Production callers wire this up to
/// `SharedPreferences`; tests inject an in-memory implementation.
abstract class WizardPreferencesStorage {
  Future<bool> getBool(String key);
  Future<void> setBool(String key, bool value);
}

/// Default in-memory storage shipped with the package. Stateful for the
/// duration of the process but does not persist across restarts — the
/// package gracefully degrades to "always assume first request" when no
/// persistent storage is supplied.
class InMemoryWizardStorage implements WizardPreferencesStorage {
  final Map<String, bool> _store = {};

  @override
  Future<bool> getBool(String key) async => _store[key] ?? false;

  @override
  Future<void> setBool(String key, bool value) async {
    _store[key] = value;
  }

  @visibleForTesting
  void clear() => _store.clear();
}
