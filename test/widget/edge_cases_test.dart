import 'package:flutter/material.dart';
import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_permission_wizard/src/core/settings_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_checker.dart';

/// Edge-case suite covering the failure modes called out in the package
/// design review: concurrent requests, lifecycle interrupts, limited and
/// provisional grants, retry budget = 0, and host-driven cancellation.
void main() {
  setUp(() => PermissionWizard.debugReset());
  tearDown(() => PermissionWizard.debugReset());

  Widget hostFor(VoidCallback onPressed) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: onPressed,
              child: const Text('go'),
            ),
          ),
        ),
      );

  testWidgets('concurrent requests are serialised by the request queue',
      (tester) async {
    final checker = FakeChecker(statusScript: [PermissionStatus.granted]);
    // Disable caching so we can prove every request hit the checker
    // (rather than short-circuiting on a cached granted status).
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
      cache: PermissionCache(ttl: Duration.zero),
    );

    final results = <PermissionWizardResult>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                final futures = List.generate(
                  3,
                  (_) => PermissionWizard.request(
                    context: ctx,
                    request: const PermissionRequest(
                      permission: Permission.camera,
                    ),
                  ),
                );
                final all = await Future.wait(futures);
                results.addAll(all);
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(results, hasLength(3));
    expect(results.every((r) => r is GrantedResult), isTrue);
    expect(checker.statusCalls, 3,
        reason: 'each serialised request should have hit the checker');
  });

  testWidgets('initial limited status yields LimitedResult and calls onGranted',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.limited],
      reportSupportsLimited: true,
    );
    final log = <String>[];
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    PermissionWizardResult? result;
    await tester.pumpWidget(hostFor(() async {
      result = await PermissionWizard.request(
        context:
            tester.element(find.byType(ElevatedButton)),
        request: PermissionRequest(
          permission: Permission.photos,
          callbacks: PermissionWizardCallbacks(
            onGranted: () => log.add('granted'),
          ),
        ),
      );
    }));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(result, isA<LimitedResult>());
    expect(log, ['granted']);
  });

  testWidgets('provisional status from initial check returns GrantedResult',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.provisional],
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    PermissionWizardResult? result;
    await tester.pumpWidget(hostFor(() async {
      result = await PermissionWizard.request(
        context: tester.element(find.byType(ElevatedButton)),
        request:
            const PermissionRequest(permission: Permission.notification),
      );
    }));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(result, isA<GrantedResult>());
  });

  testWidgets('OS request returning limited produces LimitedResult',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
      requestScript: [RequestOutcome.limited],
      reportSupportsLimited: true,
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    PermissionWizardResult? result;
    await tester.pumpWidget(hostFor(() async {
      result = await PermissionWizard.request(
        context: tester.element(find.byType(ElevatedButton)),
        request: const PermissionRequest(
          permission: Permission.photos,
          rationale: PermissionRationale(
            title: 'Photos',
            description: 'For uploads.',
          ),
        ),
      );
    }));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard.rationale.allow')));
    await tester.pumpAndSettle();
    expect(result, isA<LimitedResult>());
  });

  testWidgets('maxRetryAttempts: 0 means soft denial is immediately terminal',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
      requestScript: [RequestOutcome.deniedSoft],
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    PermissionWizardResult? result;
    await tester.pumpWidget(hostFor(() async {
      result = await PermissionWizard.request(
        context: tester.element(find.byType(ElevatedButton)),
        request: const PermissionRequest(
          permission: Permission.camera,
          rationale: PermissionRationale(title: 'T', description: 'D'),
          maxRetryAttempts: 0,
        ),
      );
    }));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard.rationale.allow')));
    await tester.pumpAndSettle();
    expect(result, isA<CancelledResult>());
    expect((result as CancelledResult).reason,
        WizardCancelReason.maxRetriesExceeded);
  });

  testWidgets('controller.cancel() during in-flight request returns cancelled',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
      requestScript: [RequestOutcome.granted],
    );
    final controller = PermissionWizardController(
      request: const PermissionRequest(
        permission: Permission.camera,
        rationale: PermissionRationale(
          title: 'Camera',
          description: 'For photos.',
        ),
      ),
      checkerOverride: checker,
      settingsLauncherOverride: FakeSettingsLauncher(),
    );

    PermissionWizardResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await controller.requestPermission(ctx);
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Camera'), findsOneWidget,
        reason: 'rationale dialog should be visible before cancel');
    expect(controller.isBusy, isTrue);
    controller.cancel();
    await tester.pumpAndSettle();
    expect(result, isA<CancelledResult>());
    expect((result as CancelledResult).reason,
        WizardCancelReason.cancelledByHost);
    expect(controller.isBusy, isFalse);
    controller.dispose();
  });

  testWidgets('controller.dispose() during in-flight request unwinds cleanly',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
      requestScript: [RequestOutcome.granted],
    );
    final controller = PermissionWizardController(
      request: const PermissionRequest(
        permission: Permission.camera,
        rationale: PermissionRationale(
          title: 'Camera',
          description: 'For photos.',
        ),
      ),
      checkerOverride: checker,
      settingsLauncherOverride: FakeSettingsLauncher(),
    );

    PermissionWizardResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await controller.requestPermission(ctx);
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    controller.dispose();
    await tester.pumpAndSettle();
    expect(result, isA<CancelledResult>());
  });

  testWidgets('app backgrounded while rationale visible cancels the wizard',
      (tester) async {
    final lifecycle = AppLifecycleObserver();
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
      requestScript: [RequestOutcome.granted],
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      lifecycle: lifecycle,
      settingsLauncher: FakeSettingsLauncher(),
    );
    PermissionWizardResult? result;
    await tester.pumpWidget(hostFor(() async {
      result = await PermissionWizard.request(
        context: tester.element(find.byType(ElevatedButton)),
        request: const PermissionRequest(
          permission: Permission.camera,
          rationale: PermissionRationale(title: 'T', description: 'D'),
        ),
      );
    }));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('T'), findsOneWidget);
    lifecycle.emit(AppLifecycleEvent.backgrounded);
    await tester.pumpAndSettle();
    expect(result, isA<CancelledResult>());
    expect((result as CancelledResult).reason,
        WizardCancelReason.appBackgrounded);
  });

  testWidgets(
      'PermissionRequest with negative maxRetryAttempts throws assertion',
      (tester) async {
    expect(
      () => PermissionRequest(
        permission: Permission.camera,
        maxRetryAttempts: -1,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  testWidgets('controller calling requestPermission after dispose is a no-op',
      (tester) async {
    final controller = PermissionWizardController(
      request: const PermissionRequest(permission: Permission.camera),
      checkerOverride:
          FakeChecker(statusScript: [PermissionStatus.granted]),
      settingsLauncherOverride: FakeSettingsLauncher(),
    );
    controller.dispose();
    await tester.pumpWidget(hostFor(() {}));
    final result = await controller
        .requestPermission(tester.element(find.byType(ElevatedButton)));
    expect(result, isA<CancelledResult>());
    expect((result as CancelledResult).reason,
        WizardCancelReason.cancelledByHost);
  });
}
