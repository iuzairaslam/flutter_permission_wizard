import 'package:flutter/material.dart';

import '../../models/permission_rationale.dart';
import '../dialogs/rationale_dialog.dart';
import '../widgets/permission_bullet_item.dart';
import '../widgets/wizard_theme_scope.dart';

/// Full-screen variant of the rationale UI. Pushed via [Navigator.push].
class RationaleFullScreen extends StatelessWidget {
  final PermissionRationale rationale;

  const RationaleFullScreen({super.key, required this.rationale});

  static Future<RationaleAction?> push(
    BuildContext context, {
    required PermissionRationale rationale,
  }) {
    return Navigator.of(context).push<RationaleAction>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RationaleFullScreen(rationale: rationale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rationale.isDismissible)
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                key: const Key('wizard.rationale.fullscreen.close'),
                icon: const Icon(Icons.close),
                onPressed: () =>
                    Navigator.of(context).pop(RationaleAction.deny),
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
                color: rationale.iconBackgroundColor ??
                    theme.resolvedIconBackground(context),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              alignment: Alignment.center,
              child: rationale.iconWidget ??
                  Icon(
                    rationale.iconData ?? Icons.lock_outline,
                    size: 40,
                    color: theme.resolvedPrimary(context),
                  ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            rationale.title,
            style: theme.resolvedTitleStyle(context).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            rationale.description,
            style: theme.resolvedBodyStyle(context).copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          if (rationale.bullets != null && rationale.bullets!.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...rationale.bullets!.map(
              (b) => PermissionBulletItem(bullet: b),
            ),
          ],
          const Spacer(),
          SizedBox(
            height: 48,
            child: FilledButton(
              key: const Key('wizard.rationale.allow'),
              style: theme.primaryButtonStyle ??
                  FilledButton.styleFrom(
                    backgroundColor: theme.resolvedPrimary(context),
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimary,
                  ),
              onPressed: () =>
                  Navigator.of(context).pop(RationaleAction.allow),
              child: Text(rationale.allowButtonText),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: TextButton(
              key: const Key('wizard.rationale.deny'),
              style: theme.secondaryButtonStyle,
              onPressed: () =>
                  Navigator.of(context).pop(RationaleAction.deny),
              child: Text(rationale.denyButtonText),
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
