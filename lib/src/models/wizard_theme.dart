import 'package:flutter/material.dart';

/// Theming overrides for the wizard UI.
///
/// Every field is optional. Any value left `null` inherits from the ambient
/// `ThemeData`, so the package automatically respects light/dark mode and
/// Material 3 color schemes out of the box.
@immutable
class WizardTheme {
  /// Color for the primary action button and accent flourishes.
  /// Defaults to `colorScheme.primary`.
  final Color? primaryColor;

  /// Background color of dialogs / sheets. Defaults to `dialogTheme.backgroundColor`
  /// or `colorScheme.surface`.
  final Color? surfaceColor;

  /// Tint of the rounded square behind the icon. Defaults to
  /// `colorScheme.primaryContainer`.
  final Color? iconBackgroundColor;

  /// Typography for the title.
  final TextStyle? titleStyle;

  /// Typography for the body / description.
  final TextStyle? bodyStyle;

  /// Style applied to the primary (Allow / Open Settings) button.
  final ButtonStyle? primaryButtonStyle;

  /// Style applied to the secondary (Skip / Not Now) button.
  final ButtonStyle? secondaryButtonStyle;

  /// Shape applied to the wrapping dialog / sheet container.
  final ShapeBorder? containerShape;

  /// Padding around the entire content. Defaults to `EdgeInsets.all(24)`.
  final EdgeInsets? contentPadding;

  /// Material elevation for the dialog. Defaults to ThemeData.
  final double? elevation;

  /// Whether to wrap full-screen layouts in [SafeArea]. Defaults to `true`.
  final bool useSafeArea;

  const WizardTheme({
    this.primaryColor,
    this.surfaceColor,
    this.iconBackgroundColor,
    this.titleStyle,
    this.bodyStyle,
    this.primaryButtonStyle,
    this.secondaryButtonStyle,
    this.containerShape,
    this.contentPadding,
    this.elevation,
    this.useSafeArea = true,
  });

  /// Returns a copy of this theme with the supplied fields overridden.
  WizardTheme copyWith({
    Color? primaryColor,
    Color? surfaceColor,
    Color? iconBackgroundColor,
    TextStyle? titleStyle,
    TextStyle? bodyStyle,
    ButtonStyle? primaryButtonStyle,
    ButtonStyle? secondaryButtonStyle,
    ShapeBorder? containerShape,
    EdgeInsets? contentPadding,
    double? elevation,
    bool? useSafeArea,
  }) {
    return WizardTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      titleStyle: titleStyle ?? this.titleStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      primaryButtonStyle: primaryButtonStyle ?? this.primaryButtonStyle,
      secondaryButtonStyle: secondaryButtonStyle ?? this.secondaryButtonStyle,
      containerShape: containerShape ?? this.containerShape,
      contentPadding: contentPadding ?? this.contentPadding,
      elevation: elevation ?? this.elevation,
      useSafeArea: useSafeArea ?? this.useSafeArea,
    );
  }
}
