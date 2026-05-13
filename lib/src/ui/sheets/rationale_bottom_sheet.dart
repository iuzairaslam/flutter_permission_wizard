import 'package:flutter/material.dart';

import '../../models/permission_rationale.dart';
import '../dialogs/rationale_dialog.dart';
import '../widgets/permission_bullet_item.dart';
import '../widgets/wizard_theme_scope.dart';

/// Bottom-sheet presentation of [PermissionRationale].
///
/// Layout matches the spec: 24-dp top rounded corners, draggable handle,
/// left-aligned content, sizes 30%–85% of viewport.
class RationaleBottomSheet extends StatelessWidget {
  final PermissionRationale rationale;

  const RationaleBottomSheet({super.key, required this.rationale});

  static Future<RationaleAction?> show(
    BuildContext context, {
    required PermissionRationale rationale,
  }) {
    return showModalBottomSheet<RationaleAction>(
      context: context,
      isScrollControlled: true,
      isDismissible: rationale.isDismissible,
      enableDrag: rationale.isDismissible,
      backgroundColor: Colors.transparent,
      builder: (_) => RationaleBottomSheet(rationale: rationale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);

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
                RationaleIconBlock(rationale: rationale, centered: false),
                const SizedBox(height: 16),
                Text(
                  rationale.title,
                  style: theme.resolvedTitleStyle(context).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  rationale.description,
                  style:
                      theme.resolvedBodyStyle(context).copyWith(fontSize: 14),
                ),
                if (rationale.bullets != null &&
                    rationale.bullets!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...rationale.bullets!.map(
                    (b) => PermissionBulletItem(bullet: b),
                  ),
                ],
                const SizedBox(height: 24),
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
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: TextButton(
                    key: const Key('wizard.rationale.deny'),
                    style: theme.secondaryButtonStyle,
                    onPressed: () =>
                        Navigator.of(context).pop(RationaleAction.deny),
                    child: Text(rationale.denyButtonText),
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
