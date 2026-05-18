import 'package:flutter/material.dart';

import '../../models/permission_denied_config.dart';
import '../../models/permission_rationale.dart';
import '../../models/wizard_theme.dart';
import 'permission_bullet_item.dart';
import 'wizard_theme_scope.dart';

/// Default rendering of the rationale icon block (rounded square + icon).
///
/// Sized via [WizardTheme.iconSize] / [WizardTheme.iconContainerSize] /
/// [WizardTheme.iconContainerRadius]. When the theme doesn't override
/// those values, [defaultContainerSize] / [defaultIconSize] /
/// [defaultRadius] are used — allowing per-layout defaults (smaller in
/// dialogs, larger in full-screen).
class DefaultRationaleIcon extends StatelessWidget {
  final PermissionRationale rationale;
  final bool centered;
  final double defaultContainerSize;
  final double defaultIconSize;
  final BorderRadius defaultRadius;

  const DefaultRationaleIcon({
    super.key,
    required this.rationale,
    this.centered = true,
    this.defaultContainerSize = 64,
    this.defaultIconSize = 32,
    this.defaultRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final bg =
        rationale.iconBackgroundColor ?? theme.resolvedIconBackground(context);
    final size = theme.iconContainerSize ?? defaultContainerSize;
    final iconSize = theme.iconSize ?? defaultIconSize;
    final radius = theme.iconContainerRadius ?? defaultRadius;

    final Widget iconChild = rationale.iconWidget ??
        Icon(
          rationale.iconData ?? Icons.lock_outline,
          size: iconSize,
          color: theme.resolvedIconColor(context),
        );

    final box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      alignment: Alignment.center,
      child: iconChild,
    );

    return centered ? Center(child: box) : box;
  }
}

/// Default rendering of the denied-screen icon block.
class DefaultDeniedIcon extends StatelessWidget {
  final PermissionDeniedConfig config;
  final bool centered;
  final double defaultContainerSize;
  final double defaultIconSize;
  final BorderRadius defaultRadius;
  final IconData defaultIcon;

  const DefaultDeniedIcon({
    super.key,
    required this.config,
    this.centered = true,
    this.defaultContainerSize = 64,
    this.defaultIconSize = 32,
    this.defaultRadius = const BorderRadius.all(Radius.circular(16)),
    this.defaultIcon = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final size = theme.iconContainerSize ?? defaultContainerSize;
    final iconSize = theme.iconSize ?? defaultIconSize;
    final radius = theme.iconContainerRadius ?? defaultRadius;

    final Widget iconChild = config.iconWidget ??
        Icon(
          config.iconData ?? defaultIcon,
          size: iconSize,
          color: theme.resolvedIconColor(context),
        );

    final box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.resolvedIconBackground(context),
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: iconChild,
    );

    return centered ? Center(child: box) : box;
  }
}

/// Default title rendering — uses the theme typography and alignment.
///
/// When the user has not supplied a [WizardTheme.titleStyle], the
/// default [defaultFontSize] / [FontWeight.w600] is applied so dialogs
/// and full-screen layouts each get their idiomatic size.
class DefaultRationaleTitle extends StatelessWidget {
  final PermissionRationale rationale;
  final TextAlign? align;
  final double defaultFontSize;
  final FontWeight defaultFontWeight;

  const DefaultRationaleTitle({
    super.key,
    required this.rationale,
    this.align,
    this.defaultFontSize = 18,
    this.defaultFontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final base = theme.resolvedTitleStyle(context);
    final hasCustomTitleStyle = theme.titleStyle != null;
    final style = hasCustomTitleStyle
        ? base
        : base.copyWith(
            fontSize: defaultFontSize,
            fontWeight: defaultFontWeight,
          );
    return Text(
      rationale.title,
      style: style,
      textAlign: theme.titleAlign ?? align ?? TextAlign.center,
    );
  }
}

/// Default description rendering.
class DefaultRationaleDescription extends StatelessWidget {
  final PermissionRationale rationale;
  final TextAlign? align;
  final double defaultFontSize;

  const DefaultRationaleDescription({
    super.key,
    required this.rationale,
    this.align,
    this.defaultFontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final base = theme.resolvedBodyStyle(context);
    final style = theme.bodyStyle != null
        ? base
        : base.copyWith(fontSize: defaultFontSize);
    return Text(
      rationale.description,
      style: style,
      textAlign: theme.descriptionAlign ?? align ?? TextAlign.center,
      maxLines: 8,
    );
  }
}

/// Default denied title rendering.
class DefaultDeniedTitle extends StatelessWidget {
  final PermissionDeniedConfig config;
  final TextAlign? align;
  final double defaultFontSize;
  final FontWeight defaultFontWeight;

  const DefaultDeniedTitle({
    super.key,
    required this.config,
    this.align,
    this.defaultFontSize = 18,
    this.defaultFontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final base = theme.resolvedTitleStyle(context);
    final style = theme.titleStyle != null
        ? base
        : base.copyWith(
            fontSize: defaultFontSize,
            fontWeight: defaultFontWeight,
          );
    return Text(
      config.title,
      style: style,
      textAlign: theme.titleAlign ?? align ?? TextAlign.center,
    );
  }
}

/// Default denied description rendering.
class DefaultDeniedDescription extends StatelessWidget {
  final PermissionDeniedConfig config;
  final TextAlign? align;
  final double defaultFontSize;

  const DefaultDeniedDescription({
    super.key,
    required this.config,
    this.align,
    this.defaultFontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final base = theme.resolvedBodyStyle(context);
    final style = theme.bodyStyle != null
        ? base
        : base.copyWith(fontSize: defaultFontSize);
    return Text(
      config.description,
      style: style,
      textAlign: theme.descriptionAlign ?? align ?? TextAlign.center,
      maxLines: 8,
    );
  }
}

/// Default bullets rendering for the rationale screen.
class DefaultRationaleBullets extends StatelessWidget {
  final PermissionRationale rationale;

  const DefaultRationaleBullets({super.key, required this.rationale});

  @override
  Widget build(BuildContext context) {
    final bullets = rationale.bullets;
    if (bullets == null || bullets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in bullets) PermissionBulletItem(bullet: b),
      ],
    );
  }
}

/// Default rationale action row, honouring [WizardTheme.actionsLayout],
/// button heights, button styles, and spacing.
///
/// Layouts can pass their own [defaultPrimaryHeight] /
/// [defaultSecondaryHeight] / [defaultSpacing] so e.g. the full-screen
/// variant can render taller buttons than the dialog variant. Theme
/// values always win when set.
class DefaultRationaleActions extends StatelessWidget {
  final PermissionRationale rationale;
  final VoidCallback onAllow;
  final VoidCallback onDeny;
  final double defaultPrimaryHeight;
  final double defaultSecondaryHeight;
  final double defaultSpacing;

  const DefaultRationaleActions({
    super.key,
    required this.rationale,
    required this.onAllow,
    required this.onDeny,
    this.defaultPrimaryHeight = 48,
    this.defaultSecondaryHeight = 40,
    this.defaultSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final primary = SizedBox(
      height: theme.primaryButtonHeight ?? defaultPrimaryHeight,
      child: FilledButton(
        key: const Key('wizard.rationale.allow'),
        style: theme.primaryButtonStyle ??
            FilledButton.styleFrom(
              backgroundColor: theme.resolvedPrimary(context),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
        onPressed: onAllow,
        child: Text(rationale.allowButtonText),
      ),
    );
    final secondary = SizedBox(
      height: theme.secondaryButtonHeight ?? defaultSecondaryHeight,
      child: TextButton(
        key: const Key('wizard.rationale.deny'),
        style: theme.secondaryButtonStyle,
        onPressed: onDeny,
        child: Text(rationale.denyButtonText),
      ),
    );

    return _StackedActions(
      primary: primary,
      secondary: secondary,
      theme: theme,
      defaultSpacing: defaultSpacing,
    );
  }
}

/// Default denied action row — open settings / retry / skip.
class DefaultDeniedActions extends StatelessWidget {
  final PermissionDeniedConfig config;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onRetry;
  final VoidCallback onSkip;
  final double defaultPrimaryHeight;
  final double defaultSecondaryHeight;
  final double defaultSpacing;

  const DefaultDeniedActions({
    super.key,
    required this.config,
    required this.onOpenSettings,
    required this.onRetry,
    required this.onSkip,
    this.defaultPrimaryHeight = 48,
    this.defaultSecondaryHeight = 40,
    this.defaultSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final primaryHeight = theme.primaryButtonHeight ?? defaultPrimaryHeight;
    final spacing = theme.actionsSpacing ?? defaultSpacing;

    final List<Widget> primaries = [];
    if (onOpenSettings != null) {
      primaries.add(SizedBox(
        height: primaryHeight,
        child: FilledButton(
          key: const Key('wizard.denied.openSettings'),
          style: theme.primaryButtonStyle ??
              FilledButton.styleFrom(
                backgroundColor: theme.resolvedPrimary(context),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
          onPressed: onOpenSettings,
          child: Text(config.openSettingsText ?? 'Open Settings'),
        ),
      ));
    }
    if (onRetry != null) {
      if (primaries.isNotEmpty) primaries.add(SizedBox(height: spacing));
      primaries.add(SizedBox(
        height: primaryHeight,
        child: FilledButton(
          key: const Key('wizard.denied.retry'),
          style: theme.primaryButtonStyle ??
              FilledButton.styleFrom(
                backgroundColor: theme.resolvedPrimary(context),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
          onPressed: onRetry,
          child: Text(config.retryText ?? 'Try Again'),
        ),
      ));
    }

    final skip = SizedBox(
      height: theme.secondaryButtonHeight ?? defaultSecondaryHeight,
      child: TextButton(
        key: const Key('wizard.denied.skip'),
        style: theme.secondaryButtonStyle,
        onPressed: onSkip,
        child: Text(config.skipText),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...primaries,
        if (primaries.isNotEmpty) SizedBox(height: spacing),
        skip,
      ],
    );
  }
}

/// Internal helper that lays out primary + secondary actions either
/// vertically or horizontally based on [WizardActionsLayout]. The primary
/// is allowed to be null (denied-screen case where neither openSettings
/// nor retry is offered).
class _StackedActions extends StatelessWidget {
  final Widget? primary;
  final Widget secondary;
  final WizardTheme theme;
  final double defaultSpacing;

  const _StackedActions({
    required this.primary,
    required this.secondary,
    required this.theme,
    this.defaultSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = theme.actionsSpacing ?? defaultSpacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = theme.useHorizontalActions(constraints.maxWidth) &&
            primary != null;
        if (horizontal) {
          return Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(child: secondary),
              SizedBox(width: spacing),
              Expanded(child: primary!),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?primary,
            if (primary != null) SizedBox(height: spacing),
            secondary,
          ],
        );
      },
    );
  }
}
