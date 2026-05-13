import 'package:flutter/material.dart';
import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_permission_wizard/src/core/settings_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_checker.dart';

void main() {
  setUp(() => PermissionWizard.debugReset());
  tearDown(() => PermissionWizard.debugReset());

  testWidgets('observer callbacks fire in the right order on a happy path',
      (tester) async {
    final log = <String>[];
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
      requestScript: [RequestOutcome.granted],
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                await PermissionWizard.request(
                  context: ctx,
                  request: PermissionRequest(
                    permission: Permission.camera,
                    rationale: const PermissionRationale(
                      title: 'T',
                      description: 'D',
                    ),
                    callbacks: PermissionWizardCallbacks(
                      onRationaleShown: () => log.add('rationaleShown'),
                      onRationaleAccepted: () => log.add('rationaleAccepted'),
                      onOSDialogPresented: () => log.add('osDialog'),
                      onGranted: () => log.add('granted'),
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
    expect(log,
        ['rationaleShown', 'rationaleAccepted', 'osDialog', 'granted']);
  });

  testWidgets(
      'onCancelled fires with rationale_dismissed when user taps deny',
      (tester) async {
    String? cancelReason;
    final checker = FakeChecker(
      statusScript: [PermissionStatus.denied],
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                await PermissionWizard.request(
                  context: ctx,
                  request: PermissionRequest(
                    permission: Permission.camera,
                    rationale: const PermissionRationale(
                      title: 'T',
                      description: 'D',
                    ),
                    callbacks: PermissionWizardCallbacks(
                      onCancelled: (reason) => cancelReason = reason,
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
    await tester.tap(find.byKey(const Key('wizard.rationale.deny')));
    await tester.pumpAndSettle();
    expect(cancelReason, WizardCancelReason.rationaleDismissed);
  });

  testWidgets('callback exceptions never crash the wizard', (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.granted],
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
                  request: PermissionRequest(
                    permission: Permission.camera,
                    callbacks: PermissionWizardCallbacks(
                      onGranted: () => throw StateError('analytics crash'),
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
    expect(result, isA<GrantedResult>());
  });
}
