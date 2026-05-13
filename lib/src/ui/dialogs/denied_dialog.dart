import 'package:flutter/material.dart';

import '../../models/permission_denied_config.dart';
import '../widgets/wizard_theme_scope.dart';

/// Internal action emitted by the denied dialog UI.
enum DeniedAction { openSettings, retry, skip }

/// Default centered-dialog implementation of [PermissionDeniedConfig].
///
/// Layout mirrors [RationaleDialog] with the action set determined by the
/// non-null fields on the config:
/// * [PermissionDeniedConfig.retryText] non-null → "Try Again" primary
/// * [PermissionDeniedConfig.openSettingsText] non-null → "Open Settings"
///   primary
/// * `skipText` is always rendered.
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
    final maxWidth = media.size.width < 340 ? media.size.width - 32.0 : 340.0;
    final showOpenSettings =
        config.openSettingsText != null && !suppressOpenSettings;
    final showRetry = config.retryText != null;

    return Dialog(
      backgroundColor: theme.resolvedSurface(context),
      surfaceTintColor: Colors.transparent,
      shape: theme.resolvedContainerShape(),
      elevation: theme.elevation,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: theme.resolvedContentPadding(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
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
              ),
              const SizedBox(height: 16),
              Text(
                config.title,
                style: theme.resolvedTitleStyle(context).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                config.description,
                style: theme.resolvedBodyStyle(context).copyWith(fontSize: 14),
                textAlign: TextAlign.center,
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
      ),
    );
  }
}
