import 'package:flutter/material.dart';
import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_permission_wizard/src/core/settings_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_checker.dart';

void main() {
  setUp(() => PermissionWizard.debugReset());
  tearDown(() => PermissionWizard.debugReset());

  testWidgets('combined batch skips when all already granted', (tester) async {
    final checker = FakeChecker(
      statusScript: [
        PermissionStatus.granted,
        PermissionStatus.granted,
      ],
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    BatchPermissionWizardResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await PermissionWizard.requestBatch(
                  context: ctx,
                  request: const BatchPermissionRequest(
                    strategy: BatchStrategy.combined,
                    batchRationale: PermissionRationale(
                      title: 'Shared',
                      description: 'Need both.',
                    ),
                    permissions: [
                      PermissionRequest(permission: Permission.camera),
                      PermissionRequest(permission: Permission.microphone),
                    ],
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
    expect(result?.allGranted, isTrue);
    expect(result?.results.length, 2);
  });

  testWidgets('combined batch rationale denial cancels every permission',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [
        PermissionStatus.denied,
        PermissionStatus.denied,
      ],
    );
    PermissionWizard.debugConfigure(
      checker: checker,
      settingsLauncher: FakeSettingsLauncher(),
    );
    BatchPermissionWizardResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await PermissionWizard.requestBatch(
                  context: ctx,
                  request: const BatchPermissionRequest(
                    strategy: BatchStrategy.combined,
                    batchRationale: PermissionRationale(
                      title: 'Allow Both',
                      description: 'For video calls.',
                    ),
                    permissions: [
                      PermissionRequest(permission: Permission.camera),
                      PermissionRequest(permission: Permission.microphone),
                    ],
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
    expect(find.text('Allow Both'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wizard.rationale.deny')));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.allGranted, isFalse);
    expect(result!.anyGranted, isFalse);
    for (final r in result!.results.values) {
      expect(r, isA<CancelledResult>());
    }
  });
}
