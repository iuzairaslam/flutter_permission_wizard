import 'package:flutter/material.dart';

import '../../models/wizard_theme.dart';

/// `InheritedWidget` that propagates a [WizardTheme] override down the
/// widget tree. Used internally by the wizard UI so deeply nested widgets
/// (custom builders, etc) can reach the active theme via [WizardThemeScope.of].
class WizardThemeScope extends InheritedWidget {
  final WizardTheme theme;

  const WizardThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  /// Resolves the active wizard theme. Falls back to a default-constructed
  /// [WizardTheme] when no scope is present.
  static WizardTheme of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<WizardThemeScope>();
    return scope?.theme ?? const WizardTheme();
  }

  /// Like [of] but does not register a dependency.
  static WizardTheme read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<WizardThemeScope>();
    return scope?.theme ?? const WizardTheme();
  }

  @override
  bool updateShouldNotify(covariant WizardThemeScope oldWidget) =>
      oldWidget.theme != theme;
}

/// Convenience getters that materialize [WizardTheme] values, falling back
/// to the ambient `ThemeData` when the [WizardTheme] field is null.
extension ResolvedWizardTheme on WizardTheme {
  Color resolvedPrimary(BuildContext context) =>
      primaryColor ?? Theme.of(context).colorScheme.primary;

  Color resolvedSurface(BuildContext context) =>
      surfaceColor ??
      Theme.of(context).dialogTheme.backgroundColor ??
      Theme.of(context).colorScheme.surface;

  Color resolvedIconBackground(BuildContext context) =>
      iconBackgroundColor ?? Theme.of(context).colorScheme.primaryContainer;

  TextStyle resolvedTitleStyle(BuildContext context) =>
      titleStyle ??
      Theme.of(context).textTheme.titleLarge ??
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

  TextStyle resolvedBodyStyle(BuildContext context) =>
      bodyStyle ??
      Theme.of(context).textTheme.bodyMedium ??
      const TextStyle(fontSize: 14);

  EdgeInsets resolvedContentPadding() =>
      contentPadding ?? const EdgeInsets.all(24);

  ShapeBorder resolvedContainerShape() =>
      containerShape ??
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      );
}
