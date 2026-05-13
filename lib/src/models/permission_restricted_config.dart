import 'package:flutter/material.dart';

/// Builder signature for a fully custom restricted screen.
typedef PermissionRestrictedBuilder = Widget Function(
  BuildContext context,
  VoidCallback onDismiss,
);

/// Configuration for the screen shown when the OS reports
/// `PermissionStatus.restricted` — typically MDM, corporate device policy or
/// parental controls. The user cannot grant the permission themselves, so
/// this screen never offers a retry or "open settings" action.
@immutable
class PermissionRestrictedConfig {
  final Widget? iconWidget;
  final IconData? iconData;
  final String title;
  final String description;
  final String dismissText;
  final PermissionRestrictedBuilder? customBuilder;

  const PermissionRestrictedConfig({
    this.title = 'Permission Restricted',
    this.description =
        'This permission is restricted on your device and cannot be granted '
            'from the app. Contact your device administrator if you believe '
            'this is a mistake.',
    this.iconWidget,
    this.iconData,
    this.dismissText = 'Got it',
    this.customBuilder,
  });
}
