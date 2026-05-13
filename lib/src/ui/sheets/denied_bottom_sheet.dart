import 'package:flutter/material.dart';

import '../../models/permission_denied_config.dart';
import '../../models/wizard_theme.dart';
import '../dialogs/denied_dialog.dart';
import '../widgets/wizard_slots.dart';
import '../widgets/wizard_theme_scope.dart';

/// Bottom-sheet presentation of [PermissionDeniedConfig]. Sizing,
/// chrome, and slot overrides all flow through the same [WizardTheme] /
/// [PermissionDeniedConfig] knobs as the other denied layouts.
class DeniedBottomSheet extends StatelessWidget {
  final PermissionDeniedConfig config;
  final bool suppressOpenSettings;

  const DeniedBottomSheet({
    super.key,
    required this.config,
    this.suppressOpenSettings = false,
  });

  static Future<DeniedAction?> show(
    BuildContext context, {
    required PermissionDeniedConfig config,
    bool suppressOpenSettings = false,
  }) {
    return showModalBottomSheet<DeniedAction>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeniedBottomSheet(
        config: config,
        suppressOpenSettings: suppressOpenSettings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final showOpenSettings =
        config.openSettingsText != null && !suppressOpenSettings;
    final showRetry = config.retryText != null;

    final VoidCallback? onOpenSettings = showOpenSettings
        ? () => Navigator.of(context).pop(DeniedAction.openSettings)
        : null;
    final VoidCallback? onRetry = showRetry
        ? () => Navigator.of(context).pop(DeniedAction.retry)
        : null;
    void onSkip() => Navigator.of(context).pop(DeniedAction.skip);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: theme.resolvedBottomSheetInitialSize(),
      minChildSize: theme.resolvedBottomSheetMinSize(),
      maxChildSize: theme.resolvedBottomSheetMaxSize(),
      builder: (context, scroll) {
        final sectionGap = theme.resolvedSectionSpacing();
        final children = <Widget>[
          _DragHandle(theme: theme),
          if (config.headerBuilder != null) ...[
            const SizedBox(height: 8),
            config.headerBuilder!(context, config),
          ],
          const SizedBox(height: 8),
          config.iconBuilder?.call(context, config) ??
              DefaultDeniedIcon(config: config, centered: false),
          SizedBox(height: sectionGap),
          config.titleBuilder?.call(context, config) ??
              DefaultDeniedTitle(config: config, align: TextAlign.start),
          const SizedBox(height: 8),
          config.descriptionBuilder?.call(context, config) ??
              DefaultDeniedDescription(config: config, align: TextAlign.start),
          SizedBox(height: sectionGap + 8),
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
          if (config.footerBuilder != null) ...[
            SizedBox(height: sectionGap),
            config.footerBuilder!(context, config),
          ],
        ];

        return Container(
          decoration: BoxDecoration(
            color: theme.resolvedSurface(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: theme.resolvedContentPadding(),
          child: SingleChildScrollView(
            controller: scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  final WizardTheme theme;
  const _DragHandle({required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = theme.dragHandleColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    if (color == Colors.transparent) return const SizedBox.shrink();
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
