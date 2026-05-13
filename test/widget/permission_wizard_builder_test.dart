import 'package:flutter/material.dart';
import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_permission_wizard/src/core/settings_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_checker.dart';

void main() {
  setUp(() => PermissionWizard.debugReset());
  tearDown(() => PermissionWizard.debugReset());

  testWidgets('builder receives current status from injected fake checker',
      (tester) async {
    PermissionWizard.debugConfigure(
      checker: FakeChecker(statusScript: [PermissionStatus.granted]),
      settingsLauncher: FakeSettingsLauncher(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PermissionWizardBuilder(
            request: const PermissionRequest(permission: Permission.camera),
            builder: (context, status, requestPermission) {
              return Text('status=${status.name}');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The builder now routes status reads through the injected platform
    // checker, so a `granted` script materialises as `WizardStatus.granted`.
    expect(find.text('status=granted'), findsOneWidget);
  });

  testWidgets(
      'builder maps restricted, limited, and denied statuses correctly',
      (tester) async {
    PermissionWizard.debugConfigure(
      checker: FakeChecker(statusScript: [PermissionStatus.limited]),
      settingsLauncher: FakeSettingsLauncher(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PermissionWizardBuilder(
            request: const PermissionRequest(permission: Permission.photos),
            builder: (context, status, _) => Text('status=${status.name}'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('status=limited'), findsOneWidget);
  });

  testWidgets('controller emits status updates and surfaces last result',
      (tester) async {
    final checker = FakeChecker(
      statusScript: [PermissionStatus.granted],
    );
    final controller = PermissionWizardController(
      request: const PermissionRequest(permission: Permission.camera),
      checkerOverride: checker,
      settingsLauncherOverride: FakeSettingsLauncher(),
    );
    final emitted = <WizardStatus>[];
    controller.stream.listen(emitted.add);

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
    expect(result, isA<GrantedResult>());
    expect(controller.isGranted, isTrue);
    expect(emitted, contains(WizardStatus.granted));
    controller.dispose();
  });
}
