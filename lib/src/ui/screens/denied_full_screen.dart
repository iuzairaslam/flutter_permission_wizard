import 'package:flutter/material.dart';

import '../../models/permission_denied_config.dart';
import '../dialogs/denied_dialog.dart';
import '../widgets/wizard_theme_scope.dart';

/// Full-screen variant of the denied UI. Pushed via [Navigator.push].
///
/// Layout per spec section 10:
/// - 80×80 icon centered
/// - 22sp title, 15sp body (centered)
/// - Action buttons stacked at the bottom with SafeArea + 24dp padding
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
    final showOpenSettings =
        config.openSettingsText != null && !suppressOpenSettings;
    final showRetry = config.retryText != null;

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDismissible)
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                key: const Key('wizard.denied.fullscreen.close'),
                icon: const Icon(Icons.close),
                onPressed: () =>
                    Navigator.of(context).pop(DeniedAction.skip),
              ),
            )
          else
            const SizedBox(height: 48),
          const Spacer(),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.resolvedIconBackground(context),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              alignment: Alignment.center,
              child: config.iconWidget ??
                  Icon(
                    config.iconData ?? Icons.lock_outline,
                    size: 40,
                    color: theme.resolvedPrimary(context),
                  ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            config.title,
            style: theme.resolvedTitleStyle(context).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            config.description,
            style: theme.resolvedBodyStyle(context).copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          if (showOpenSettings)
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const Key('wizard.denied.openSettings'),
                style: theme.primaryButtonStyle ??
                    FilledButton.styleFrom(
                      backgroundColor: theme.resolvedPrimary(context),
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                    ),
                onPressed: () =>
                    Navigator.of(context).pop(DeniedAction.openSettings),
                child: Text(config.openSettingsText!),
              ),
            ),
          if (showRetry) ...[
            if (showOpenSettings) const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const Key('wizard.denied.retry'),
                style: theme.primaryButtonStyle ??
                    FilledButton.styleFrom(
                      backgroundColor: theme.resolvedPrimary(context),
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                    ),
                onPressed: () =>
                    Navigator.of(context).pop(DeniedAction.retry),
                child: Text(config.retryText!),
              ),
            ),
          ],
          if (showOpenSettings || showRetry) const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: TextButton(
              key: const Key('wizard.denied.skip'),
              style: theme.secondaryButtonStyle,
              onPressed: () =>
                  Navigator.of(context).pop(DeniedAction.skip),
              child: Text(config.skipText),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.resolvedSurface(context),
      body: theme.useSafeArea ? SafeArea(child: body) : body,
    );
  }
}
