import 'package:flutter/widgets.dart';

/// A single bullet point inside the rationale UI describing one reason the
/// permission is needed.
///
/// Bullets are optional. They render below the rationale description and are
/// useful for batch requests where you want to enumerate every permission
/// the user is about to grant.
@immutable
class PermissionBullet {
  /// Leading icon (e.g. `Icons.camera_alt`).
  final IconData icon;

  /// Short label shown next to the icon.
  final String label;

  /// Optional secondary line shown below [label].
  final String? sublabel;

  const PermissionBullet({
    required this.icon,
    required this.label,
    this.sublabel,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PermissionBullet &&
        other.icon == icon &&
        other.label == label &&
        other.sublabel == sublabel;
  }

  @override
  int get hashCode => Object.hash(icon, label, sublabel);
}
