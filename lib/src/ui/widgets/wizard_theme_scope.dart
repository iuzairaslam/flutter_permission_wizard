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
    final scope = context.getInheritedWidgetOfExactType<WizardThemeScope>();
    return scope?.theme ?? const WizardTheme();
  }

  @override
  bool updateShouldNotify(covariant WizardThemeScope oldWidget) =>
      oldWidget.theme != theme;
}

/// Convenience getters that materialize [WizardTheme] values, falling back
/// to the ambient `ThemeData` when the [WizardTheme] field is null.
///
/// Custom builders supplied via `PermissionRationale.iconBuilder` etc.
/// can call these helpers to render in lock-step with the rest of the
/// wizard UI.
extension ResolvedWizardTheme on WizardTheme {
  Color resolvedPrimary(BuildContext context) =>
      primaryColor ?? Theme.of(context).colorScheme.primary;

  Color resolvedSurface(BuildContext context) =>
      surfaceColor ??
      Theme.of(context).dialogTheme.backgroundColor ??
      Theme.of(context).colorScheme.surface;

  Color resolvedIconBackground(BuildContext context) =>
      iconBackgroundColor ?? Theme.of(context).colorScheme.primaryContainer;

  Color resolvedIconColor(BuildContext context) =>
      iconColor ?? resolvedPrimary(context);

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

  double resolvedSectionSpacing() => sectionSpacing ?? 16;

  double resolvedActionsSpacing() => actionsSpacing ?? 8;

  double resolvedPrimaryButtonHeight() => primaryButtonHeight ?? 48;

  double resolvedSecondaryButtonHeight() => secondaryButtonHeight ?? 40;

  double resolvedIconSize() => iconSize ?? 32;

  double resolvedIconContainerSize() => iconContainerSize ?? 64;

  BorderRadius resolvedIconContainerRadius() =>
      iconContainerRadius ??
      const BorderRadius.all(Radius.circular(16));

  double resolvedDialogMaxWidth() => dialogMaxWidth ?? 340;

  double resolvedBottomSheetInitialSize() => bottomSheetInitialSize ?? 0.6;

  double resolvedBottomSheetMinSize() => bottomSheetMinSize ?? 0.45;

  double resolvedBottomSheetMaxSize() => bottomSheetMaxSize ?? 0.9;

  /// Whether actions should render horizontally given the current
  /// `BoxConstraints` width. Honours [WizardActionsLayout.auto].
  bool useHorizontalActions(double availableWidth) {
    switch (actionsLayout) {
      case WizardActionsLayout.horizontal:
        return true;
      case WizardActionsLayout.vertical:
        return false;
      case WizardActionsLayout.auto:
        return availableWidth >= actionsHorizontalBreakpoint;
    }
  }
}
