import 'package:flutter/material.dart';

import '../../models/permission_denied_config.dart';
import '../widgets/wizard_slots.dart';
import '../widgets/wizard_theme_scope.dart';

/// Internal action emitted by the denied dialog UI.
enum DeniedAction { openSettings, retry, skip }

/// Default centered-dialog implementation of [PermissionDeniedConfig].
///
/// Layout mirrors [RationaleDialog]: every section is driven by
/// [WizardTheme] knobs and by the per-slot builders on the supplied
/// [PermissionDeniedConfig]. The action set is determined by which of
/// `openSettingsText` / `retryText` are non-null (plus the always-on
/// `skipText`).
class DeniedDialog extends StatelessWidget {
  final PermissionDeniedConfig config;

  /// When `true`, the "open settings" action is hidden regardless of
  /// `openSettingsText` (used after a fruitless Settings round-trip, per
  /// section 9 of the spec).
  final bool suppressOpenSettings;

  const DeniedDialog({
    super.key,
    required this.config,
    this.suppressOpenSettings = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final media = MediaQuery.of(context);
    final cap = theme.resolvedDialogMaxWidth();
    final maxWidth = media.size.width < cap ? media.size.width - 32.0 : cap;
    final sectionGap = theme.resolvedSectionSpacing();

    final showOpenSettings =
        config.openSettingsText != null && !suppressOpenSettings;
    final showRetry = config.retryText != null;

    VoidCallback? onOpenSettings = showOpenSettings
        ? () => Navigator.of(context).pop(DeniedAction.openSettings)
        : null;
    VoidCallback? onRetry = showRetry
        ? () => Navigator.of(context).pop(DeniedAction.retry)
        : null;
    void onSkip() => Navigator.of(context).pop(DeniedAction.skip);

    final children = <Widget>[];
    if (config.headerBuilder != null) {
      children
        ..add(config.headerBuilder!(context, config))
        ..add(SizedBox(height: sectionGap));
    }
    children.add(
      config.iconBuilder?.call(context, config) ??
          DefaultDeniedIcon(config: config),
    );
    children.add(SizedBox(height: sectionGap));
    children.add(
      config.titleBuilder?.call(context, config) ??
          DefaultDeniedTitle(config: config),
    );
    children.add(const SizedBox(height: 8));
    children.add(
      config.descriptionBuilder?.call(context, config) ??
          DefaultDeniedDescription(config: config),
    );
    children.add(SizedBox(height: sectionGap + 8));
    children.add(
      config.actionsBuilder?.call(
            context,
            config,
            onOpenSettings,
            onRetry,
            onSkip,
          ) ??
          DefaultDeniedActions(
            config: config,
            onOpenSettings: onOpenSettings,
            onRetry: onRetry,
            onSkip: onSkip,
          ),
    );
    if (config.footerBuilder != null) {
      children
        ..add(SizedBox(height: sectionGap))
        ..add(config.footerBuilder!(context, config));
    }

    return Dialog(
      backgroundColor: theme.resolvedSurface(context),
      surfaceTintColor: Colors.transparent,
      shape: theme.resolvedContainerShape(),
      elevation: theme.elevation,
      insetPadding: theme.dialogInsetPadding ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: theme.resolvedContentPadding(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
