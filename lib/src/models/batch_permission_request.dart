import 'package:flutter/foundation.dart';

import 'enums.dart';
import 'permission_rationale.dart';
import 'permission_request.dart';
import 'permission_wizard_callbacks.dart';
import 'wizard_theme.dart';

/// Configuration for [PermissionWizard.requestBatch], which handles multiple
/// permissions in a single wizard session.
///
/// See [BatchStrategy] for the two run modes.
@immutable
class BatchPermissionRequest {
  /// Combined → shared rationale, sequential OS prompts.
  /// Sequential → run each permission's wizard end-to-end before moving on.
  final BatchStrategy strategy;

  /// Required when [strategy] is [BatchStrategy.combined]. Ignored otherwise.
  final PermissionRationale? batchRationale;

  /// Per-permission configuration. For [BatchStrategy.combined] only the
  /// per-permission `denied*` content and callbacks are used — the
  /// `rationale` field of each entry is intentionally ignored.
  final List<PermissionRequest> permissions;

  /// Wizard-wide theme. Falls back to the first permission's theme, then to
  /// the ambient `ThemeData`.
  final WizardTheme? theme;

  /// Batch-level callbacks fired at most once for the whole flow.
  final PermissionWizardCallbacks? callbacks;

  /// When `true` and *every* permission is already granted the wizard skips
  /// the shared rationale entirely and returns immediately. Default `true`.
  final bool skipIfAllGranted;

  const BatchPermissionRequest({
    required this.strategy,
    required this.permissions,
    this.batchRationale,
    this.theme,
    this.callbacks,
    this.skipIfAllGranted = true,
  });
}
