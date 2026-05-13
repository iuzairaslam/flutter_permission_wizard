import 'package:flutter/material.dart';
import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_permission_wizard/src/core/settings_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_checker.dart';

void main() {
  setUp(() => PermissionWizard.debugReset());
  tearDown(() => PermissionWizard.debugReset());

  testWidgets('soft denial → retry → grant ends with GrantedResult',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
      requestScript: [RequestOutcome.deniedSoft, RequestOutcome.granted],
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
                      title: 'Try again',
                      description: 'We still need it.',
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
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wizard.denied.retry')));
    await tester.pumpAndSettle();
    expect(result, isA<GrantedResult>());
    expect(checker.requestCalls, 2);
  });

  testWidgets('soft denial → exceeding retries → CancelledResult(max_retries)',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
      requestScript: [
        RequestOutcome.deniedSoft,
        RequestOutcome.deniedSoft,
      ],
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
                      title: 'Try again',
                      description: 'Need it.',
                      retryText: 'Try Again',
                      skipText: 'Skip',
                    ),
                    maxRetryAttempts: 1,
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
    await tester.tap(find.byKey(const Key('wizard.denied.retry')));
    await tester.pumpAndSettle();
    expect(result, isA<CancelledResult>());
    expect(
      (result as CancelledResult).reason,
      WizardCancelReason.maxRetriesExceeded,
    );
  });
}
