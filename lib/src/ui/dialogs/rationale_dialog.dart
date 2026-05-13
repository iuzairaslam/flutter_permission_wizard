import 'package:flutter/material.dart';

import '../../models/permission_rationale.dart';
import '../widgets/wizard_slots.dart';
import '../widgets/wizard_theme_scope.dart';

/// Internal action emitted by the rationale UI. Public so the wizard
/// orchestrator can dispatch on it.
enum RationaleAction { allow, deny }

/// Default centered-dialog implementation of [PermissionRationale].
///
/// Layout is now fully driven by [WizardTheme] (icon sizing, paddings,
/// spacing, button heights, actions layout, dialog width) and by the
/// per-slot builders on [PermissionRationale] — see the class docs on
/// `PermissionRationale` for the customisation strategy.
class RationaleDialog extends StatelessWidget {
  final PermissionRationale rationale;

  const RationaleDialog({super.key, required this.rationale});

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final media = MediaQuery.of(context);
    final cap = theme.resolvedDialogMaxWidth();
    final maxWidth = media.size.width < cap ? media.size.width - 32.0 : cap;

    void allow() => Navigator.of(context).pop(RationaleAction.allow);
    void deny() => Navigator.of(context).pop(RationaleAction.deny);

    final sectionGap = theme.resolvedSectionSpacing();

    final children = <Widget>[];
    if (rationale.headerBuilder != null) {
      children
        ..add(rationale.headerBuilder!(context, rationale))
        ..add(SizedBox(height: sectionGap));
    }
    children.add(
      rationale.iconBuilder?.call(context, rationale) ??
          DefaultRationaleIcon(rationale: rationale),
    );
    children.add(SizedBox(height: sectionGap));
    children.add(
      rationale.titleBuilder?.call(context, rationale) ??
          DefaultRationaleTitle(rationale: rationale),
    );
    children.add(const SizedBox(height: 8));
    children.add(
      rationale.descriptionBuilder?.call(context, rationale) ??
          DefaultRationaleDescription(rationale: rationale),
    );
    if (rationale.bullets != null && rationale.bullets!.isNotEmpty ||
        rationale.bulletsBuilder != null) {
      children.add(SizedBox(height: sectionGap));
      children.add(
        rationale.bulletsBuilder?.call(context, rationale) ??
            DefaultRationaleBullets(rationale: rationale),
      );
    }
    children.add(SizedBox(height: sectionGap + 8));
    children.add(
      rationale.actionsBuilder?.call(context, rationale, allow, deny) ??
          DefaultRationaleActions(
            rationale: rationale,
            onAllow: allow,
            onDeny: deny,
          ),
    );
    if (rationale.footerBuilder != null) {
      children
        ..add(SizedBox(height: sectionGap))
        ..add(rationale.footerBuilder!(context, rationale));
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

/// Public alias retained for back-compat with the old icon-block widget.
/// Defers to the new shared [DefaultRationaleIcon].
class RationaleIconBlock extends StatelessWidget {
  final PermissionRationale rationale;
  final bool centered;
  const RationaleIconBlock({
    super.key,
    required this.rationale,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) =>
      DefaultRationaleIcon(rationale: rationale, centered: centered);
}
