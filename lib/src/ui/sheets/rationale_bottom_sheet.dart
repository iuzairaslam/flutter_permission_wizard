import 'package:flutter/material.dart';

import '../../models/permission_rationale.dart';
import '../../models/wizard_theme.dart';
import '../dialogs/rationale_dialog.dart';
import '../widgets/wizard_slots.dart';
import '../widgets/wizard_theme_scope.dart';

/// Bottom-sheet presentation of [PermissionRationale].
///
/// Layout and sizing are driven by [WizardTheme]:
/// [WizardTheme.bottomSheetInitialSize], `Min`, `Max`,
/// `dragHandleColor`, plus the standard chrome knobs. Per-slot builders
/// on [PermissionRationale] override individual sections.
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

    void allow() => Navigator.of(context).pop(RationaleAction.allow);
    void deny() => Navigator.of(context).pop(RationaleAction.deny);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: theme.resolvedBottomSheetInitialSize(),
      minChildSize: theme.resolvedBottomSheetMinSize(),
      maxChildSize: theme.resolvedBottomSheetMaxSize(),
      builder: (context, scroll) {
        final sectionGap = theme.resolvedSectionSpacing();
        final children = <Widget>[
          _DragHandle(theme: theme),
          if (rationale.headerBuilder != null) ...[
            const SizedBox(height: 8),
            rationale.headerBuilder!(context, rationale),
          ],
          const SizedBox(height: 8),
          rationale.iconBuilder?.call(context, rationale) ??
              DefaultRationaleIcon(rationale: rationale, centered: false),
          SizedBox(height: sectionGap),
          rationale.titleBuilder?.call(context, rationale) ??
              DefaultRationaleTitle(
                rationale: rationale,
                align: TextAlign.start,
              ),
          const SizedBox(height: 8),
          rationale.descriptionBuilder?.call(context, rationale) ??
              DefaultRationaleDescription(
                rationale: rationale,
                align: TextAlign.start,
              ),
          if (rationale.bullets != null && rationale.bullets!.isNotEmpty ||
              rationale.bulletsBuilder != null) ...[
            SizedBox(height: sectionGap),
            rationale.bulletsBuilder?.call(context, rationale) ??
                DefaultRationaleBullets(rationale: rationale),
          ],
          SizedBox(height: sectionGap + 8),
          rationale.actionsBuilder?.call(context, rationale, allow, deny) ??
              DefaultRationaleActions(
                rationale: rationale,
                onAllow: allow,
                onDeny: deny,
              ),
          if (rationale.footerBuilder != null) ...[
            SizedBox(height: sectionGap),
            rationale.footerBuilder!(context, rationale),
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
