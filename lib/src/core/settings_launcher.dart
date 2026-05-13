import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around `app_settings` so we can swap it out in tests.
///
/// The default implementation routes every permission to the app's own
/// "app info" page, which is the most consistent landing point across iOS
/// and Android. Some teams prefer routing photo permissions to the dedicated
/// photo settings page — pass [target] to override.
class SettingsLauncher {
  final AppSettingsType target;
  final Future<void> Function(AppSettingsType type)? overrideOpen;

  const SettingsLauncher({
    this.target = AppSettingsType.settings,
    this.overrideOpen,
  });

  /// Opens the device settings page. Returns when the platform call has
  /// completed — the user may or may not have actually navigated yet.
  Future<void> open() async {
    if (overrideOpen != null) {
      await overrideOpen!(target);
      return;
    }
    await AppSettings.openAppSettings(type: target);
  }
}

/// In-memory stub used by tests.
@visibleForTesting
class FakeSettingsLauncher extends SettingsLauncher {
  int openCount = 0;
  FakeSettingsLauncher() : super();

  @override
  Future<void> open() async {
    openCount += 1;
  }
}
