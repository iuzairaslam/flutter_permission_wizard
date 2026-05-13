import 'package:flutter/material.dart';

/// Direction in which the wizard's action buttons stack.
///
/// * [WizardActionsLayout.vertical] — primary on top of secondary, full-width
///   (the default).
/// * [WizardActionsLayout.horizontal] — primary and secondary side-by-side.
/// * [WizardActionsLayout.auto] — vertical when the dialog is below
///   [WizardTheme.actionsHorizontalBreakpoint] in width, horizontal above.
enum WizardActionsLayout { vertical, horizontal, auto }

/// Theming overrides for the wizard UI.
///
/// Every field is optional. Any value left `null` inherits from the ambient
/// `ThemeData`, so the package automatically respects light/dark mode and
/// Material 3 color schemes out of the box.
///
/// Theme works at three levels of granularity:
///
/// 1. **Colors / typography / shape** — `primaryColor`, `surfaceColor`,
///    `titleStyle`, `containerShape`, etc.
/// 2. **Layout** — `contentPadding`, `sectionSpacing`, `actionsLayout`,
///    `actionsSpacing`, `dialogMaxWidth`, button heights.
/// 3. **Behaviour** — `barrierColor`, `useSafeArea`, `bottomSheetInitialSize`,
///    `bottomSheetMaxSize`, etc.
///
/// For one-shot tweaks prefer the named-argument constructor; for
/// derivative themes use [copyWith]; and for a couple of opinionated
/// looks straight out of the box use the [WizardTheme.compact],
/// [WizardTheme.expressive], or [WizardTheme.minimal] factories.
@immutable
class WizardTheme {
  // ---------------------------------------------------------------------------
  // Colors
  // ---------------------------------------------------------------------------

  /// Color for the primary action button and accent flourishes.
  /// Defaults to `colorScheme.primary`.
  final Color? primaryColor;

  /// Background color of dialogs / sheets. Defaults to
  /// `dialogTheme.backgroundColor` or `colorScheme.surface`.
  final Color? surfaceColor;

  /// Tint of the rounded square behind the icon. Defaults to
  /// `colorScheme.primaryContainer`.
  final Color? iconBackgroundColor;

  /// Foreground tint of the default `Icon` rendered inside the icon
  /// container. Defaults to [primaryColor].
  final Color? iconColor;

  /// Color of the scrim drawn behind the dialog / sheet. Defaults to the
  /// platform default (typically black with 54% opacity).
  final Color? barrierColor;

  /// Color of the small drag handle drawn at the top of bottom sheets.
  /// Set to [Colors.transparent] to hide it.
  final Color? dragHandleColor;

  // ---------------------------------------------------------------------------
  // Typography
  // ---------------------------------------------------------------------------

  /// Typography for the title.
  final TextStyle? titleStyle;

  /// Typography for the body / description.
  final TextStyle? bodyStyle;

  /// Horizontal alignment for the title text. Defaults to
  /// [TextAlign.center] in dialogs and bottom sheets, [TextAlign.start]
  /// in the full-screen layout.
  final TextAlign? titleAlign;

  /// Horizontal alignment for the description text. Same defaults as
  /// [titleAlign].
  final TextAlign? descriptionAlign;

  // ---------------------------------------------------------------------------
  // Buttons
  // ---------------------------------------------------------------------------

  /// Style applied to the primary (Allow / Open Settings) button.
  final ButtonStyle? primaryButtonStyle;

  /// Style applied to the secondary (Skip / Not Now) button.
  final ButtonStyle? secondaryButtonStyle;

  /// Height of the primary button. Defaults to `48`.
  final double? primaryButtonHeight;

  /// Height of the secondary button. Defaults to `40`.
  final double? secondaryButtonHeight;

  /// Direction in which the wizard's action buttons stack. Defaults to
  /// [WizardActionsLayout.vertical].
  final WizardActionsLayout actionsLayout;

  /// Below this width the [WizardActionsLayout.auto] mode falls back to
  /// vertical. Defaults to `420` logical pixels.
  final double actionsHorizontalBreakpoint;

  /// Gap between the primary and secondary action buttons. Defaults to
  /// `8`.
  final double? actionsSpacing;

  // ---------------------------------------------------------------------------
  // Container chrome
  // ---------------------------------------------------------------------------

  /// Shape applied to the wrapping dialog / sheet container.
  final ShapeBorder? containerShape;

  /// Padding around the entire content. Defaults to `EdgeInsets.all(24)`.
  final EdgeInsets? contentPadding;

  /// Spacing between consecutive sections (icon → title → description →
  /// bullets → actions). Defaults to `16`.
  final double? sectionSpacing;

  /// Material elevation for the dialog. Defaults to ThemeData.
  final double? elevation;

  /// Maximum width of the dialog layout. Defaults to `340`.
  final double? dialogMaxWidth;

  /// Padding applied between the dialog and the screen edges. Defaults
  /// to the Material default.
  final EdgeInsets? dialogInsetPadding;

  // ---------------------------------------------------------------------------
  // Icon container
  // ---------------------------------------------------------------------------

  /// Size of the icon rendered inside the icon container. Defaults to
  /// `32`.
  final double? iconSize;

  /// Width and height of the rounded square behind the icon. Defaults
  /// to `64`.
  final double? iconContainerSize;

  /// Border radius of the icon container. Defaults to
  /// `BorderRadius.all(Radius.circular(16))`.
  final BorderRadius? iconContainerRadius;

  // ---------------------------------------------------------------------------
  // Bottom sheet sizing
  // ---------------------------------------------------------------------------

  /// Initial fractional height of the bottom-sheet layout. `0.0`–`1.0`.
  /// Defaults to `0.6`.
  final double? bottomSheetInitialSize;

  /// Minimum fractional height the bottom-sheet layout can be dragged
  /// down to. Defaults to `0.45`.
  final double? bottomSheetMinSize;

  /// Maximum fractional height the bottom-sheet layout can be dragged
  /// up to. Defaults to `0.9`.
  final double? bottomSheetMaxSize;

  // ---------------------------------------------------------------------------
  // Misc
  // ---------------------------------------------------------------------------

  /// Whether to wrap full-screen layouts in [SafeArea]. Defaults to `true`.
  final bool useSafeArea;

  /// Optional builder used to wrap dialog/sheet content in a custom
  /// transition or `AnimatedSwitcher`. Receives the resolved theme and
  /// the wizard child. When `null` the framework's default animation is
  /// used.
  final Widget Function(BuildContext context, Widget child)?
      transitionBuilder;

  const WizardTheme({
    this.primaryColor,
    this.surfaceColor,
    this.iconBackgroundColor,
    this.iconColor,
    this.barrierColor,
    this.dragHandleColor,
    this.titleStyle,
    this.bodyStyle,
    this.titleAlign,
    this.descriptionAlign,
    this.primaryButtonStyle,
    this.secondaryButtonStyle,
    this.primaryButtonHeight,
    this.secondaryButtonHeight,
    this.actionsLayout = WizardActionsLayout.vertical,
    this.actionsHorizontalBreakpoint = 420,
    this.actionsSpacing,
    this.containerShape,
    this.contentPadding,
    this.sectionSpacing,
    this.elevation,
    this.dialogMaxWidth,
    this.dialogInsetPadding,
    this.iconSize,
    this.iconContainerSize,
    this.iconContainerRadius,
    this.bottomSheetInitialSize,
    this.bottomSheetMinSize,
    this.bottomSheetMaxSize,
    this.useSafeArea = true,
    this.transitionBuilder,
  });

  /// Compact preset — tighter padding, smaller icon, ideal for
  /// information-dense apps and tablet layouts where the default 24-pixel
  /// rhythm feels too airy.
  factory WizardTheme.compact() => const WizardTheme(
        contentPadding: EdgeInsets.all(16),
        sectionSpacing: 12,
        iconContainerSize: 48,
        iconSize: 24,
        primaryButtonHeight: 44,
        secondaryButtonHeight: 36,
        dialogMaxWidth: 320,
      );

  /// Expressive preset — larger icon, more breathing room, Material 3
  /// `expressive` typography vibe.
  factory WizardTheme.expressive() => const WizardTheme(
        contentPadding: EdgeInsets.all(32),
        sectionSpacing: 20,
        iconContainerSize: 80,
        iconSize: 40,
        primaryButtonHeight: 56,
        secondaryButtonHeight: 48,
        dialogMaxWidth: 380,
        containerShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        iconContainerRadius: BorderRadius.all(Radius.circular(24)),
      );

  /// Minimal preset — no icon container background, no border radius
  /// flourish. Suitable for apps that want the wizard to look like a
  /// stock Material `AlertDialog`.
  factory WizardTheme.minimal() => const WizardTheme(
        iconBackgroundColor: Colors.transparent,
        iconContainerSize: 40,
        iconSize: 32,
        contentPadding: EdgeInsets.all(20),
        sectionSpacing: 14,
        containerShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        iconContainerRadius: BorderRadius.zero,
      );

  /// Returns a copy of this theme with the supplied fields overridden.
  WizardTheme copyWith({
    Color? primaryColor,
    Color? surfaceColor,
    Color? iconBackgroundColor,
    Color? iconColor,
    Color? barrierColor,
    Color? dragHandleColor,
    TextStyle? titleStyle,
    TextStyle? bodyStyle,
    TextAlign? titleAlign,
    TextAlign? descriptionAlign,
    ButtonStyle? primaryButtonStyle,
    ButtonStyle? secondaryButtonStyle,
    double? primaryButtonHeight,
    double? secondaryButtonHeight,
    WizardActionsLayout? actionsLayout,
    double? actionsHorizontalBreakpoint,
    double? actionsSpacing,
    ShapeBorder? containerShape,
    EdgeInsets? contentPadding,
    double? sectionSpacing,
    double? elevation,
    double? dialogMaxWidth,
    EdgeInsets? dialogInsetPadding,
    double? iconSize,
    double? iconContainerSize,
    BorderRadius? iconContainerRadius,
    double? bottomSheetInitialSize,
    double? bottomSheetMinSize,
    double? bottomSheetMaxSize,
    bool? useSafeArea,
    Widget Function(BuildContext context, Widget child)? transitionBuilder,
  }) {
    return WizardTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      iconColor: iconColor ?? this.iconColor,
      barrierColor: barrierColor ?? this.barrierColor,
      dragHandleColor: dragHandleColor ?? this.dragHandleColor,
      titleStyle: titleStyle ?? this.titleStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      titleAlign: titleAlign ?? this.titleAlign,
      descriptionAlign: descriptionAlign ?? this.descriptionAlign,
      primaryButtonStyle: primaryButtonStyle ?? this.primaryButtonStyle,
      secondaryButtonStyle: secondaryButtonStyle ?? this.secondaryButtonStyle,
      primaryButtonHeight: primaryButtonHeight ?? this.primaryButtonHeight,
      secondaryButtonHeight:
          secondaryButtonHeight ?? this.secondaryButtonHeight,
      actionsLayout: actionsLayout ?? this.actionsLayout,
      actionsHorizontalBreakpoint:
          actionsHorizontalBreakpoint ?? this.actionsHorizontalBreakpoint,
      actionsSpacing: actionsSpacing ?? this.actionsSpacing,
      containerShape: containerShape ?? this.containerShape,
      contentPadding: contentPadding ?? this.contentPadding,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      elevation: elevation ?? this.elevation,
      dialogMaxWidth: dialogMaxWidth ?? this.dialogMaxWidth,
      dialogInsetPadding: dialogInsetPadding ?? this.dialogInsetPadding,
      iconSize: iconSize ?? this.iconSize,
      iconContainerSize: iconContainerSize ?? this.iconContainerSize,
      iconContainerRadius: iconContainerRadius ?? this.iconContainerRadius,
      bottomSheetInitialSize:
          bottomSheetInitialSize ?? this.bottomSheetInitialSize,
      bottomSheetMinSize: bottomSheetMinSize ?? this.bottomSheetMinSize,
      bottomSheetMaxSize: bottomSheetMaxSize ?? this.bottomSheetMaxSize,
      useSafeArea: useSafeArea ?? this.useSafeArea,
      transitionBuilder: transitionBuilder ?? this.transitionBuilder,
    );
  }

  /// Merge this theme with [other], with [other]'s non-null fields taking
  /// precedence. Useful for layering an opinionated preset onto an
  /// app-wide base.
  WizardTheme mergeWith(WizardTheme other) {
    return copyWith(
      primaryColor: other.primaryColor,
      surfaceColor: other.surfaceColor,
      iconBackgroundColor: other.iconBackgroundColor,
      iconColor: other.iconColor,
      barrierColor: other.barrierColor,
      dragHandleColor: other.dragHandleColor,
      titleStyle: other.titleStyle,
      bodyStyle: other.bodyStyle,
      titleAlign: other.titleAlign,
      descriptionAlign: other.descriptionAlign,
      primaryButtonStyle: other.primaryButtonStyle,
      secondaryButtonStyle: other.secondaryButtonStyle,
      primaryButtonHeight: other.primaryButtonHeight,
      secondaryButtonHeight: other.secondaryButtonHeight,
      actionsLayout: other.actionsLayout,
      actionsHorizontalBreakpoint: other.actionsHorizontalBreakpoint,
      actionsSpacing: other.actionsSpacing,
      containerShape: other.containerShape,
      contentPadding: other.contentPadding,
      sectionSpacing: other.sectionSpacing,
      elevation: other.elevation,
      dialogMaxWidth: other.dialogMaxWidth,
      dialogInsetPadding: other.dialogInsetPadding,
      iconSize: other.iconSize,
      iconContainerSize: other.iconContainerSize,
      iconContainerRadius: other.iconContainerRadius,
      bottomSheetInitialSize: other.bottomSheetInitialSize,
      bottomSheetMinSize: other.bottomSheetMinSize,
      bottomSheetMaxSize: other.bottomSheetMaxSize,
      useSafeArea: other.useSafeArea,
      transitionBuilder: other.transitionBuilder,
    );
  }
}
