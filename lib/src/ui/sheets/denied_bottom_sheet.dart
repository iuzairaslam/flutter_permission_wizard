import 'package:flutter/material.dart';

import '../../models/permission_denied_config.dart';
import '../dialogs/denied_dialog.dart';
import '../widgets/wizard_theme_scope.dart';

/// Bottom-sheet presentation of [PermissionDeniedConfig].
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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scroll) {
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
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.resolvedIconBackground(context),
                    borderRadius:
                        const BorderRadius.all(Radius.circular(16)),
                  ),
                  alignment: Alignment.center,
                  child: config.iconWidget ??
                      Icon(
                        config.iconData ?? Icons.lock_outline,
                        size: 32,
                        color: theme.resolvedPrimary(context),
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  config.title,
                  style: theme.resolvedTitleStyle(context).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  config.description,
                  style:
                      theme.resolvedBodyStyle(context).copyWith(fontSize: 14),
                ),
                const SizedBox(height: 24),
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
                  if (showOpenSettings) const SizedBox(height: 8),
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
                if (showOpenSettings || showRetry) const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: TextButton(
                    key: const Key('wizard.denied.skip'),
                    style: theme.secondaryButtonStyle,
                    onPressed: () =>
                        Navigator.of(context).pop(DeniedAction.skip),
                    child: Text(config.skipText),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
