import 'package:flutter/material.dart';
import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_permission_wizard/src/core/settings_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_checker.dart';

void main() {
  setUp(() => PermissionWizard.debugReset());
  tearDown(() => PermissionWizard.debugReset());

  Future<PermissionWizardResult> runWizard(
    WidgetTester tester, {
    required FakeChecker checker,
    required PermissionRequest request,
    FakeSettingsLauncher? settings,
    AppLifecycleObserver? lifecycle,
  }) async {
    PermissionWizard.debugConfigure(
      checker: checker,
      lifecycle: lifecycle,
      settingsLauncher: settings ?? FakeSettingsLauncher(),
    );
    PermissionWizardResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await PermissionWizard.request(
                  context: ctx,
                  request: request,
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    // The wizard returns once UI flows complete.
    // Some tests may need a tester action between to finish the flow.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    return result ?? const CancelledResult(reason: 'no_result');
  }

  testWidgets('granted at status check returns GrantedResult immediately',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.granted],
    );
    final result = await runWizard(
      tester,
      checker: checker,
      request: const PermissionRequest(permission: Permission.camera),
    );
    expect(result, isA<GrantedResult>());
    expect(checker.requestCalls, 0);
  });

  testWidgets('restricted at status check returns RestrictedResult',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.restricted],
    );
    final result = await runWizard(
      tester,
      checker: checker,
      request: const PermissionRequest(permission: Permission.camera),
    );
    expect(result, isA<RestrictedResult>());
  });

  testWidgets('user denies rationale → CancelledResult(rationale_dismissed)',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    PermissionWizardResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await PermissionWizard.request(
                  context: ctx,
                  request: const PermissionRequest(
                    permission: Permission.camera,
                    rationale: PermissionRationale(
                      title: 'Need Camera',
                      description: 'Why we need it.',
                    ),
                  ),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Need Camera'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wizard.rationale.deny')));
    await tester.pumpAndSettle();
    expect(result, isA<CancelledResult>());
    expect(
      (result as CancelledResult).reason,
      WizardCancelReason.rationaleDismissed,
    );
    expect(checker.requestCalls, 0);
  });

  testWidgets('rationale → allow → OS granted → GrantedResult',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
      requestScript: [RequestOutcome.granted],
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    PermissionWizardResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await PermissionWizard.request(
                  context: ctx,
                  request: const PermissionRequest(
                    permission: Permission.camera,
                    rationale: PermissionRationale(
                      title: 'Need Camera',
                      description: 'Why we need it.',
                    ),
                  ),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard.rationale.allow')));
    await tester.pumpAndSettle();
    expect(result, isA<GrantedResult>());
    expect(checker.requestCalls, 1);
  });

  testWidgets('soft denial → user skips → DeniedResult(isPermanent: false)',
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
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await PermissionWizard.request(
                  context: ctx,
                  request: const PermissionRequest(
                    permission: Permission.camera,
                    rationale: PermissionRationale(
                      title: 'R',
                      description: 'D',
                    ),
                    deniedConfig: PermissionDeniedConfig(
                      title: 'Need it',
                      description: 'Try again or skip.',
                      retryText: 'Try Again',
                      skipText: 'Skip',
                    ),
                  ),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard.rationale.allow')));
    await tester.pumpAndSettle();
    expect(find.text('Need it'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wizard.denied.skip')));
    await tester.pumpAndSettle();
    expect(result, isA<DeniedResult>());
    expect((result as DeniedResult).isPermanent, isFalse);
  });

  testWidgets('permanent denial → open settings → return granted',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [
        PermissionStatus.denied, // initial check
        PermissionStatus.granted, // after settings round-trip
      ],
      requestScript: [RequestOutcome.deniedPermanent],
    );
    final lifecycle = AppLifecycleObserver();
    final settings = FakeSettingsLauncher();
    PermissionWizard.debugConfigure(
      checker: checker,
      lifecycle: lifecycle,
      settingsLauncher: settings,
    );

    PermissionWizardResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await PermissionWizard.request(
                  context: ctx,
                  request: const PermissionRequest(
                    permission: Permission.camera,
                    rationale: PermissionRationale(
                      title: 'R',
                      description: 'D',
                    ),
                    permanentlyDeniedConfig: PermissionDeniedConfig(
                      title: 'Blocked',
                      description: 'Open settings to enable.',
                      openSettingsText: 'Open Settings',
                      skipText: 'Skip',
                    ),
                    settingsReturnDelay: Duration(milliseconds: 10),
                  ),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard.rationale.allow')));
    await tester.pumpAndSettle();
    expect(find.text('Blocked'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wizard.denied.openSettings')));
    await tester.pumpAndSettle();
    expect(settings.openCount, 1);

    // Simulate the user returning to the app from settings.
    lifecycle.emit(AppLifecycleEvent.resumed);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(result, isA<GrantedResult>());
  });

  testWidgets(
      'permanent denial → open settings → still denied → re-show without open settings button',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [
        PermissionStatus.denied,
        PermissionStatus.permanentlyDenied,
      ],
      requestScript: [RequestOutcome.deniedPermanent],
    );
    final lifecycle = AppLifecycleObserver();
    final settings = FakeSettingsLauncher();
    PermissionWizard.debugConfigure(
      checker: checker,
      lifecycle: lifecycle,
      settingsLauncher: settings,
    );

    PermissionWizardResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await PermissionWizard.request(
                  context: ctx,
                  request: const PermissionRequest(
                    permission: Permission.camera,
                    rationale: PermissionRationale(
                      title: 'R',
                      description: 'D',
                    ),
                    permanentlyDeniedConfig: PermissionDeniedConfig(
                      title: 'Blocked',
                      description: 'Open settings to enable.',
                      openSettingsText: 'Open Settings',
                      skipText: 'Skip',
                    ),
                    settingsReturnDelay: Duration(milliseconds: 10),
                  ),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard.rationale.allow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard.denied.openSettings')));
    await tester.pumpAndSettle();
    lifecycle.emit(AppLifecycleEvent.resumed);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    // After the round-trip, the open settings button is suppressed.
    expect(find.byKey(const Key('wizard.denied.openSettings')), findsNothing);
    expect(find.byKey(const Key('wizard.denied.skip')), findsOneWidget);
    await tester.tap(find.byKey(const Key('wizard.denied.skip')));
    await tester.pumpAndSettle();
    expect(result, isA<DeniedResult>());
    expect((result as DeniedResult).isPermanent, isTrue);
  });

  testWidgets('rationale is skipped when already asked before', (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
      requestScript: [RequestOutcome.granted],
      alreadyAsked: true,
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    PermissionWizardResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await PermissionWizard.request(
                  context: ctx,
                  request: const PermissionRequest(
                    permission: Permission.camera,
                    rationale: PermissionRationale(
                      title: 'Need Camera',
                      description: 'Why we need it.',
                    ),
                  ),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Need Camera'), findsNothing);
    expect(result, isA<GrantedResult>());
  });

  testWidgets('initial permanent denial skips OS dialog', (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.permanentlyDenied],
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    PermissionWizardResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await PermissionWizard.request(
                  context: ctx,
                  request: const PermissionRequest(
                    permission: Permission.camera,
                    permanentlyDeniedConfig: PermissionDeniedConfig(
                      title: 'Blocked',
                      description: 'Permanent.',
                      openSettingsText: 'Open Settings',
                      skipText: 'Skip',
                    ),
                  ),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Blocked'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wizard.denied.skip')));
    await tester.pumpAndSettle();
    expect(result, isA<DeniedResult>());
    expect((result as DeniedResult).isPermanent, isTrue);
    expect(checker.requestCalls, 0);
  });
}
