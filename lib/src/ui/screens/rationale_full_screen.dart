import 'package:flutter/material.dart';

import '../../models/permission_rationale.dart';
import '../dialogs/rationale_dialog.dart';
import '../widgets/wizard_slots.dart';
import '../widgets/wizard_theme_scope.dart';

/// Full-screen variant of the rationale UI. Pushed via [Navigator.push].
/// Honours every slot builder on [PermissionRationale] plus the layout
/// knobs on [WizardTheme].
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
    final sectionGap = theme.resolvedSectionSpacing();
    void allow() => Navigator.of(context).pop(RationaleAction.allow);
    void deny() => Navigator.of(context).pop(RationaleAction.deny);

    final children = <Widget>[
      if (rationale.isDismissible)
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            key: const Key('wizard.rationale.fullscreen.close'),
            icon: const Icon(Icons.close),
            onPressed: deny,
          ),
        )
      else
        const SizedBox(height: 48),
      const Spacer(),
      if (rationale.headerBuilder != null) ...[
        rationale.headerBuilder!(context, rationale),
        SizedBox(height: sectionGap),
      ],
      rationale.iconBuilder?.call(context, rationale) ??
          DefaultRationaleIcon(
            rationale: rationale,
            defaultContainerSize: 80,
            defaultIconSize: 40,
            defaultRadius: const BorderRadius.all(Radius.circular(20)),
          ),
      SizedBox(height: sectionGap + 8),
      rationale.titleBuilder?.call(context, rationale) ??
          DefaultRationaleTitle(
            rationale: rationale,
            defaultFontSize: 22,
            defaultFontWeight: FontWeight.bold,
          ),
      const SizedBox(height: 12),
      rationale.descriptionBuilder?.call(context, rationale) ??
          DefaultRationaleDescription(
            rationale: rationale,
            defaultFontSize: 15,
          ),
      if (rationale.bullets != null && rationale.bullets!.isNotEmpty ||
          rationale.bulletsBuilder != null) ...[
        SizedBox(height: sectionGap + 8),
        rationale.bulletsBuilder?.call(context, rationale) ??
            DefaultRationaleBullets(rationale: rationale),
      ],
      const Spacer(),
      rationale.actionsBuilder?.call(context, rationale, allow, deny) ??
          DefaultRationaleActions(
            rationale: rationale,
            onAllow: allow,
            onDeny: deny,
            defaultSecondaryHeight: 48,
            defaultSpacing: 16,
          ),
      if (rationale.footerBuilder != null) ...[
        SizedBox(height: sectionGap),
        rationale.footerBuilder!(context, rationale),
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
