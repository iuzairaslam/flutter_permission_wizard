import 'package:flutter/material.dart';

import '../../models/permission_denied_config.dart';
import '../dialogs/denied_dialog.dart';
import '../widgets/wizard_slots.dart';
import '../widgets/wizard_theme_scope.dart';

/// Full-screen variant of the denied UI. Pushed via [Navigator.push].
/// Honours every slot builder on [PermissionDeniedConfig] plus the
/// layout knobs on [WizardTheme].
class DeniedFullScreen extends StatelessWidget {
  final PermissionDeniedConfig config;
  final bool suppressOpenSettings;
  final bool isDismissible;

  const DeniedFullScreen({
    super.key,
    required this.config,
    this.suppressOpenSettings = false,
    this.isDismissible = false,
  });

  /// Push as a full-screen route and await the user's action.
  static Future<DeniedAction?> push(
    BuildContext context, {
    required PermissionDeniedConfig config,
    bool suppressOpenSettings = false,
    bool isDismissible = false,
  }) {
    return Navigator.of(context).push<DeniedAction>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DeniedFullScreen(
          config: config,
          suppressOpenSettings: suppressOpenSettings,
          isDismissible: isDismissible,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final sectionGap = theme.resolvedSectionSpacing();
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

    final children = <Widget>[
      if (isDismissible)
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            key: const Key('wizard.denied.fullscreen.close'),
            icon: const Icon(Icons.close),
            onPressed: onSkip,
          ),
        )
      else
        const SizedBox(height: 48),
      const Spacer(),
      if (config.headerBuilder != null) ...[
        config.headerBuilder!(context, config),
        SizedBox(height: sectionGap),
      ],
      config.iconBuilder?.call(context, config) ??
          DefaultDeniedIcon(
            config: config,
            defaultContainerSize: 80,
            defaultIconSize: 40,
            defaultRadius: const BorderRadius.all(Radius.circular(20)),
          ),
      SizedBox(height: sectionGap + 8),
      config.titleBuilder?.call(context, config) ??
          DefaultDeniedTitle(
            config: config,
            defaultFontSize: 22,
            defaultFontWeight: FontWeight.bold,
          ),
      const SizedBox(height: 12),
      config.descriptionBuilder?.call(context, config) ??
          DefaultDeniedDescription(
            config: config,
            defaultFontSize: 15,
          ),
      const Spacer(),
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
            defaultSecondaryHeight: 48,
            defaultSpacing: 16,
          ),
      if (config.footerBuilder != null) ...[
        SizedBox(height: sectionGap),
        config.footerBuilder!(context, config),
      ],
      const SizedBox(height: 24),
    ];

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    return Scaffold(
      backgroundColor: theme.resolvedSurface(context),
      body: theme.useSafeArea ? SafeArea(child: body) : body,
    );
  }
}
