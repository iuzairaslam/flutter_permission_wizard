import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_lifecycle_observer.dart';
import '../../core/permission_wizard.dart';
import '../../models/permission_request.dart';
import '../../models/permission_wizard_result.dart';
import '../../state/wizard_status.dart';

/// Reactive builder widget that exposes the current [WizardStatus] for a
/// permission and a `requestPermission` callback that drives the wizard.
///
/// Typical use:
///
/// ```dart
/// PermissionWizardBuilder(
///   request: PermissionRequest(
///     permission: Permission.location,
///     rationale: PermissionRationale(...),
///   ),
///   builder: (context, status, requestPermission) {
///     return switch (status) {
///       WizardStatus.granted    => MapWidget(),
///       WizardStatus.denied     => TextButton(
///         onPressed: requestPermission,
///         child: Text('Enable Location'),
///       ),
///       WizardStatus.restricted => RestrictedPlaceholder(),
///       _                       => CircularProgressIndicator(),
///     };
///   },
/// );
/// ```
///
/// The widget automatically:
///  * checks the current status when first inserted into the tree;
///  * re-checks the status whenever the app resumes (so external Settings
///    changes are reflected without manual intervention);
///  * runs the wizard when `requestPermission` is invoked.
typedef PermissionWizardWidgetBuilder = Widget Function(
  BuildContext context,
  WizardStatus status,
  Future<PermissionWizardResult> Function() requestPermission,
);

class PermissionWizardBuilder extends StatefulWidget {
  final PermissionRequest request;
  final PermissionWizardWidgetBuilder builder;

  /// Whether the widget should auto-trigger the wizard on the first frame
  /// when the current status is `denied` (and the permission has never been
  /// requested before). Defaults to `false` — callers explicitly invoke
  /// `requestPermission` from the builder.
  final bool autoRequestOnFirstShow;

  const PermissionWizardBuilder({
    super.key,
    required this.request,
    required this.builder,
    this.autoRequestOnFirstShow = false,
  });

  @override
  State<PermissionWizardBuilder> createState() =>
      _PermissionWizardBuilderState();
}

class _PermissionWizardBuilderState extends State<PermissionWizardBuilder>
    with WidgetsBindingObserver {
  WizardStatus _status = WizardStatus.checking;
  bool _autoRequestFired = false;
  StreamSubscription<AppLifecycleEvent>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void didUpdateWidget(covariant PermissionWizardBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.permission != widget.request.permission) {
      _refreshStatus();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    // Route through PermissionWizard.resolveChecker so tests installing a
    // fake via `PermissionWizard.debugConfigure(checker: ...)` see their
    // checker honoured here.
    final checker = PermissionWizard.resolveChecker();
    PermissionStatus raw;
    try {
      raw = await checker.status(widget.request.permission);
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'flutter_permission_wizard',
        context: ErrorDescription(
          'while polling permission status in PermissionWizardBuilder',
        ),
      ));
      return;
    }
    if (!mounted) return;
    final mapped = _mapStatus(raw);
    if (mapped != _status) {
      setState(() => _status = mapped);
    }
    if (widget.autoRequestOnFirstShow &&
        !_autoRequestFired &&
        mapped == WizardStatus.denied) {
      _autoRequestFired = true;
      unawaited(_runWizard());
    }
  }

  Future<PermissionWizardResult> _runWizard() async {
    setState(() => _status = WizardStatus.inProgress);
    final result = await PermissionWizard.request(
      context: context,
      request: widget.request,
    );
    if (!mounted) return result;
    setState(() {
      _status = switch (result) {
        GrantedResult() => WizardStatus.granted,
        LimitedResult() => WizardStatus.limited,
        DeniedResult() => WizardStatus.denied,
        RestrictedResult() => WizardStatus.restricted,
        CancelledResult() => WizardStatus.cancelled,
      };
    });
    return result;
  }

  WizardStatus _mapStatus(PermissionStatus raw) {
    if (raw.isGranted || raw.isProvisional) return WizardStatus.granted;
    if (raw.isLimited) return WizardStatus.limited;
    if (raw.isRestricted) return WizardStatus.restricted;
    if (raw.isPermanentlyDenied) return WizardStatus.denied;
    if (raw.isDenied) return WizardStatus.denied;
    return WizardStatus.initial;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _status, _runWizard);
}
