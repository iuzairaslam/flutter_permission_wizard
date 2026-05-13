import 'package:flutter/material.dart';

import '../../models/permission_rationale.dart';
import '../dialogs/rationale_dialog.dart';
import 'rationale_bottom_sheet.dart';

/// Convenience helper exposing the batch-mode rationale UI. The visual
/// component is structurally identical to [RationaleBottomSheet] — the only
/// reason this exists is to give batch flows a stable namespace and to
/// emphasise that the rationale here applies to *every* permission in the
/// batch.
class BatchRationaleSheet {
  const BatchRationaleSheet._();

  static Future<RationaleAction?> show(
    BuildContext context, {
    required PermissionRationale rationale,
  }) {
    return RationaleBottomSheet.show(context, rationale: rationale);
  }
}
