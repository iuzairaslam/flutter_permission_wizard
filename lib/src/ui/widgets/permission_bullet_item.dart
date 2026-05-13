import 'package:flutter/material.dart';

import '../../models/permission_bullet.dart';
import 'wizard_theme_scope.dart';

/// Renders a single [PermissionBullet] inside the rationale UI.
///
/// Layout: 20-dp leading icon, 8-dp gap, then the label/sublabel column.
class PermissionBulletItem extends StatelessWidget {
  final PermissionBullet bullet;

  const PermissionBulletItem({super.key, required this.bullet});

  @override
  Widget build(BuildContext context) {
    final theme = WizardThemeScope.of(context);
    final labelStyle = theme.resolvedBodyStyle(context).copyWith(fontSize: 13);
    final subStyle = labelStyle.copyWith(
      color: labelStyle.color?.withValues(alpha: 0.7) ??
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      fontSize: 12,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            bullet.icon,
            size: 20,
            color: theme.resolvedPrimary(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bullet.label, style: labelStyle),
                if (bullet.sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(bullet.sublabel!, style: subStyle),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
