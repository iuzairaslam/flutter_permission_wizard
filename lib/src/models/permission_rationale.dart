import 'package:flutter/material.dart';

import 'enums.dart';
import 'permission_bullet.dart';

/// Builder signature for a fully custom rationale UI.
///
/// The package will call this with the two callbacks it normally wires up to
/// the built-in buttons. Invoking [onAllow] triggers the OS request; invoking
/// [onDeny] cancels the wizard with reason `rationale_dismissed`.
typedef PermissionRationaleBuilder = Widget Function(
  BuildContext context,
  VoidCallback onAllow,
  VoidCallback onDeny,
);

/// Configuration for the rationale screen shown *before* the OS permission
/// dialog appears.
///
/// The rationale exists so the user understands *why* the permission is being
/// requested, dramatically improving acceptance rates compared to the bare
/// OS prompt.
///
/// All values are immutable. To override individual fields create a new
/// instance via [copyWith].
@immutable
class PermissionRationale {
  /// Custom widget for the icon area. Wins over [iconData] when set.
  final Widget? iconWidget;

  /// Convenience field — when [iconWidget] is null this icon is rendered at
  /// a default 32-logical-pixel size inside the icon container.
  final IconData? iconData;

  /// Background color of the rounded square behind the icon. Falls back to
  /// `colorScheme.primaryContainer` when null.
  final Color? iconBackgroundColor;

  /// Headline shown above the description.
  final String title;

  /// Body explaining why the permission is needed. Keep it short — three
  /// lines maximum before the layout scrolls.
  final String description;

  /// Optional bullet list rendered between [description] and the action
  /// buttons.
  final List<PermissionBullet>? bullets;

  /// Primary (allow) button label. Defaults to `'Allow'`.
  final String allowButtonText;

  /// Secondary (deny) button label. Defaults to `'Not Now'`.
  final String denyButtonText;

  /// Presentation style — dialog, bottom sheet, or full screen.
  final RationaleStyle style;

  /// Whether tapping the scrim / pressing back dismisses the rationale.
  /// Defaults to `false` — the user must consciously pick allow or deny.
  final bool isDismissible;

  /// Escape hatch to replace the entire rationale UI with a custom widget.
  /// When set, all other fields except behavioural ones (`style`,
  /// `isDismissible`) are ignored.
  final PermissionRationaleBuilder? customBuilder;

  const PermissionRationale({
    required this.title,
    required this.description,
    this.iconWidget,
    this.iconData,
    this.iconBackgroundColor,
    this.bullets,
    this.allowButtonText = 'Allow',
    this.denyButtonText = 'Not Now',
    this.style = RationaleStyle.dialog,
    this.isDismissible = false,
    this.customBuilder,
  });

  /// Returns a copy of this rationale with the given fields replaced.
  PermissionRationale copyWith({
    Widget? iconWidget,
    IconData? iconData,
    Color? iconBackgroundColor,
    String? title,
    String? description,
    List<PermissionBullet>? bullets,
    String? allowButtonText,
    String? denyButtonText,
    RationaleStyle? style,
    bool? isDismissible,
    PermissionRationaleBuilder? customBuilder,
  }) {
    return PermissionRationale(
      iconWidget: iconWidget ?? this.iconWidget,
      iconData: iconData ?? this.iconData,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      title: title ?? this.title,
      description: description ?? this.description,
      bullets: bullets ?? this.bullets,
      allowButtonText: allowButtonText ?? this.allowButtonText,
      denyButtonText: denyButtonText ?? this.denyButtonText,
      style: style ?? this.style,
      isDismissible: isDismissible ?? this.isDismissible,
      customBuilder: customBuilder ?? this.customBuilder,
    );
  }
}
