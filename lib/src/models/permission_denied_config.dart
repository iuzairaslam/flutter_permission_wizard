import 'package:flutter/material.dart';

import 'enums.dart';

/// Builder signature for a fully custom denied screen.
///
/// [onOpenSettings] and [onRetry] are non-null only when the wizard wants to
/// offer that action. [onSkip] is always present.
typedef PermissionDeniedBuilder = Widget Function(
  BuildContext context,
  VoidCallback? onOpenSettings,
  VoidCallback? onRetry,
  VoidCallback onSkip,
);

/// Builder signature for a single denied-screen *slot*.
typedef PermissionDeniedSlotBuilder = Widget Function(
  BuildContext context,
  PermissionDeniedConfig config,
);

/// Builder signature for the denied-screen action row.
typedef PermissionDeniedActionsBuilder = Widget Function(
  BuildContext context,
  PermissionDeniedConfig config,
  VoidCallback? onOpenSettings,
  VoidCallback? onRetry,
  VoidCallback onSkip,
);

/// Configuration for the screen shown after the user denies the OS prompt.
///
/// Two distinct instances are typically supplied to a
/// [PermissionRequest]: one for *soft* denial (Android only) where a retry is
/// possible, and one for *permanent* denial where the user must visit
/// Settings.
///
/// See [PermissionRationale] for a detailed write-up of the customisation
/// strategy (text overrides → [WizardTheme] → per-slot builders →
/// header / footer → fully custom). The denied screen exposes the same
/// layered API.
@immutable
class PermissionDeniedConfig {
  final Widget? iconWidget;
  final IconData? iconData;
  final String title;
  final String description;

  /// Label for the "Open Settings" button. When `null` the button is hidden
  /// (useful for soft-denial UIs or when you want to ban the Settings loop
  /// after a user has already been there once).
  final String? openSettingsText;

  /// Label for the "Try Again" button. When `null` the button is hidden.
  /// Only meaningful in the soft-denial flow.
  final String? retryText;

  /// Always-visible "Skip" button label. Defaults to `'Skip'`.
  final String skipText;

  /// Presentation style.
  final DeniedStyle style;

  // ---------------------------------------------------------------------------
  // Per-slot builders (composable customisation)
  // ---------------------------------------------------------------------------

  /// Replace only the icon section.
  final PermissionDeniedSlotBuilder? iconBuilder;

  /// Replace only the title section.
  final PermissionDeniedSlotBuilder? titleBuilder;

  /// Replace only the description section.
  final PermissionDeniedSlotBuilder? descriptionBuilder;

  /// Replace only the action row. Receives the (optional)
  /// open-settings / retry callbacks and the always-on skip callback.
  final PermissionDeniedActionsBuilder? actionsBuilder;

  /// Widget rendered *above* the icon section.
  final PermissionDeniedSlotBuilder? headerBuilder;

  /// Widget rendered *below* the action buttons.
  final PermissionDeniedSlotBuilder? footerBuilder;

  /// Custom override. When set, all other slot builders and field
  /// overrides are ignored — only [style] still applies.
  final PermissionDeniedBuilder? customBuilder;

  const PermissionDeniedConfig({
    required this.title,
    required this.description,
    this.iconWidget,
    this.iconData,
    this.openSettingsText,
    this.retryText,
    this.skipText = 'Skip',
    this.style = DeniedStyle.dialog,
    this.iconBuilder,
    this.titleBuilder,
    this.descriptionBuilder,
    this.actionsBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.customBuilder,
  });

  PermissionDeniedConfig copyWith({
    Widget? iconWidget,
    IconData? iconData,
    String? title,
    String? description,
    Object? openSettingsText = _sentinel,
    Object? retryText = _sentinel,
    String? skipText,
    DeniedStyle? style,
    PermissionDeniedSlotBuilder? iconBuilder,
    PermissionDeniedSlotBuilder? titleBuilder,
    PermissionDeniedSlotBuilder? descriptionBuilder,
    PermissionDeniedActionsBuilder? actionsBuilder,
    PermissionDeniedSlotBuilder? headerBuilder,
    PermissionDeniedSlotBuilder? footerBuilder,
    PermissionDeniedBuilder? customBuilder,
  }) {
    return PermissionDeniedConfig(
      iconWidget: iconWidget ?? this.iconWidget,
      iconData: iconData ?? this.iconData,
      title: title ?? this.title,
      description: description ?? this.description,
      openSettingsText: identical(openSettingsText, _sentinel)
          ? this.openSettingsText
          : openSettingsText as String?,
      retryText: identical(retryText, _sentinel)
          ? this.retryText
          : retryText as String?,
      skipText: skipText ?? this.skipText,
      style: style ?? this.style,
      iconBuilder: iconBuilder ?? this.iconBuilder,
      titleBuilder: titleBuilder ?? this.titleBuilder,
      descriptionBuilder: descriptionBuilder ?? this.descriptionBuilder,
      actionsBuilder: actionsBuilder ?? this.actionsBuilder,
      headerBuilder: headerBuilder ?? this.headerBuilder,
      footerBuilder: footerBuilder ?? this.footerBuilder,
      customBuilder: customBuilder ?? this.customBuilder,
    );
  }
}

// Sentinel value so callers can explicitly null-out optional buttons via
// `copyWith(openSettingsText: null)`.
const Object _sentinel = Object();
