import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';

/// Scriptable in-memory implementation of [PlatformPermissionChecker] used
/// by widget tests. Each scenario lists the sequence of statuses and the
/// sequence of request outcomes the checker should return.
class FakeChecker implements PlatformPermissionChecker {
  final List<PermissionStatus> statusScript;
  final List<RequestOutcome> requestScript;
  final bool reportSupportsLimited;
  bool alreadyAsked;

  int statusCalls = 0;
  int requestCalls = 0;

  FakeChecker({
    required this.statusScript,
    this.requestScript = const [],
    this.reportSupportsLimited = false,
    this.alreadyAsked = false,
  });

  @override
  bool get supportsLimited => reportSupportsLimited;

  @override
  Future<PermissionStatus> status(Permission permission) async {
    final index =
        statusCalls < statusScript.length ? statusCalls : statusScript.length - 1;
    statusCalls += 1;
    return statusScript[index];
  }

  @override
  Future<RequestOutcome> request(Permission permission) async {
    final index =
        requestCalls < requestScript.length ? requestCalls : requestScript.length - 1;
    requestCalls += 1;
    alreadyAsked = true;
    return requestScript[index];
  }

  @override
  Future<bool> canRequestAgain(Permission permission) async => !alreadyAsked;

  @override
  Future<bool> hasBeenAskedBefore(Permission permission) async => alreadyAsked;

  @override
  Future<void> markAsAsked(Permission permission) async {
    alreadyAsked = true;
  }
}
