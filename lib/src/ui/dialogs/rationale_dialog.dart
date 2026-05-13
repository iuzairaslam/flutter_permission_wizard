import 'package:flutter/material.dart';

import '../../models/permission_rationale.dart';
import '../widgets/permission_bullet_item.dart';
import '../widgets/wizard_theme_scope.dart';

/// Internal action emitted by the rationale UI. Public so the wizard
/// orchestrator can dispatch on it.
enum RationaleAction { allow, deny }

/// Default centered-dialog implementation of [PermissionRationale].
///
/// Layout follows the spec in section 10 of the technical requirements:
/// 340-dp max width, 64×64 icon container, 18sp title, 14sp body, full-width
/// primary button (48dp), text-style secondary (40dp).
class RationaleDialog extends StatelessWidget {
  final PermissionRationale rationale;

  const RationaleDialog({super.key, required this.rationale});

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width < 340 ? media.size.width - 32.0 : 340.0;

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
              _IconBlock(rationale: rationale, centered: true),
              const SizedBox(height: 16),
              Text(
                rationale.title,
                style: theme.resolvedTitleStyle(context).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                rationale.description,
                style: theme.resolvedBodyStyle(context).copyWith(fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 5,
              ),
              if (rationale.bullets != null && rationale.bullets!.isNotEmpty) ...[
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
      ),
    );
  }
}

/// Shared icon block reused by every rationale layout (dialog / sheet /
/// full-screen).
class _IconBlock extends StatelessWidget {
  final PermissionRationale rationale;
  final bool centered;

  const _IconBlock({required this.rationale, this.centered = true});

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final bg = rationale.iconBackgroundColor ?? theme.resolvedIconBackground(context);

    final Widget iconChild = rationale.iconWidget ??
        Icon(
          rationale.iconData ?? Icons.lock_outline,
          size: 32,
          color: theme.resolvedPrimary(context),
        );

    final box = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      alignment: Alignment.center,
      child: iconChild,
    );

    return centered ? Center(child: box) : box;
  }
}

/// Public version of the internal `_IconBlock` for use by other rationale
/// presentations (bottom sheet, full screen).
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
      _IconBlock(rationale: rationale, centered: centered);
}
