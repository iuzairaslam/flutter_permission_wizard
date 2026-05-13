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

/// Builder signature for a single rationale *slot* (icon, title, body, etc).
///
/// Slot builders compose with the rest of the default layout, so the user
/// only has to override the piece they care about. Reach the active
/// [WizardTheme] via `WizardThemeScope.of(context)` if you want to render
/// in lock-step with the rest of the wizard.
typedef PermissionRationaleSlotBuilder = Widget Function(
  BuildContext context,
  PermissionRationale rationale,
);

/// Builder signature for the action row (allow / deny buttons).
typedef PermissionRationaleActionsBuilder = Widget Function(
  BuildContext context,
  PermissionRationale rationale,
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
/// **Customisation strategy** (from lightest touch to heaviest):
///
/// 1. **Text & icon overrides** — supply [title], [description],
///    [iconData], [iconWidget], [allowButtonText], [denyButtonText]. The
///    default layout is preserved.
/// 2. **[WizardTheme]** — change colors, padding, button heights, action
///    layout, bottom-sheet sizing globally.
/// 3. **Per-slot builders** — replace just one section
///    ([iconBuilder], [titleBuilder], [descriptionBuilder],
///    [bulletsBuilder], [actionsBuilder]) while keeping the rest of the
///    default layout intact.
/// 4. **[headerBuilder] / [footerBuilder]** — inject extra widgets above
///    or below the standard content (badges, fine print, illustrations).
/// 5. **[customBuilder]** — completely replace the entire UI.
///
/// All values are immutable. To override individual fields create a new
/// instance via [copyWith].
@immutable
class PermissionRationale {
  /// Custom widget for the icon area. Wins over [iconData] when set.
  final Widget? iconWidget;

  /// Convenience field — when [iconWidget] is null this icon is rendered at
  /// the theme's [WizardTheme.iconSize] inside the icon container.
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

  // ---------------------------------------------------------------------------
  // Per-slot builders (composable customisation)
  // ---------------------------------------------------------------------------

  /// Replace only the icon section. Receives the rationale config so you
  /// can read [iconData] / [iconWidget] / [iconBackgroundColor] yourself.
  final PermissionRationaleSlotBuilder? iconBuilder;

  /// Replace only the title section.
  final PermissionRationaleSlotBuilder? titleBuilder;

  /// Replace only the description section.
  final PermissionRationaleSlotBuilder? descriptionBuilder;

  /// Replace only the bullet list.
  final PermissionRationaleSlotBuilder? bulletsBuilder;

  /// Replace only the action button row. Receives the allow/deny
  /// callbacks the package would normally wire to its built-in buttons.
  final PermissionRationaleActionsBuilder? actionsBuilder;

  /// Widget rendered *above* the icon section, inside the same padding /
  /// scroll area. Useful for badges, "Required for v3.2" callouts, etc.
  final PermissionRationaleSlotBuilder? headerBuilder;

  /// Widget rendered *below* the action buttons, inside the same padding.
  /// Common uses: privacy-policy fine print, "We never share your data"
  /// disclaimers.
  final PermissionRationaleSlotBuilder? footerBuilder;

  /// Escape hatch to replace the entire rationale UI with a custom widget.
  /// When set, all other slot builders and field overrides are ignored —
  /// only [style] and [isDismissible] still apply.
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
    this.iconBuilder,
    this.titleBuilder,
    this.descriptionBuilder,
    this.bulletsBuilder,
    this.actionsBuilder,
    this.headerBuilder,
    this.footerBuilder,
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
    PermissionRationaleSlotBuilder? iconBuilder,
    PermissionRationaleSlotBuilder? titleBuilder,
    PermissionRationaleSlotBuilder? descriptionBuilder,
    PermissionRationaleSlotBuilder? bulletsBuilder,
    PermissionRationaleActionsBuilder? actionsBuilder,
    PermissionRationaleSlotBuilder? headerBuilder,
    PermissionRationaleSlotBuilder? footerBuilder,
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
      iconBuilder: iconBuilder ?? this.iconBuilder,
      titleBuilder: titleBuilder ?? this.titleBuilder,
      descriptionBuilder: descriptionBuilder ?? this.descriptionBuilder,
      bulletsBuilder: bulletsBuilder ?? this.bulletsBuilder,
      actionsBuilder: actionsBuilder ?? this.actionsBuilder,
      headerBuilder: headerBuilder ?? this.headerBuilder,
      footerBuilder: footerBuilder ?? this.footerBuilder,
      customBuilder: customBuilder ?? this.customBuilder,
    );
  }
}
