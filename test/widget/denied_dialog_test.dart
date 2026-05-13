import 'package:flutter/material.dart';
import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_permission_wizard/src/ui/dialogs/denied_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDenied(
    WidgetTester tester,
    PermissionDeniedConfig config, {
    bool suppressOpenSettings = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => DeniedDialog(
                  config: config,
                  suppressOpenSettings: suppressOpenSettings,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows open settings + skip in permanent denial', (tester) async {
    await pumpDenied(
      tester,
      const PermissionDeniedConfig(
        title: 'Camera blocked',
        description: 'Open settings to enable it.',
        openSettingsText: 'Open Settings',
        skipText: 'Skip',
      ),
    );
    expect(find.text('Camera blocked'), findsOneWidget);
    expect(find.byKey(const Key('wizard.denied.openSettings')), findsOneWidget);
    expect(find.byKey(const Key('wizard.denied.retry')), findsNothing);
    expect(find.byKey(const Key('wizard.denied.skip')), findsOneWidget);
  });

  testWidgets('shows retry + skip in soft denial', (tester) async {
    await pumpDenied(
      tester,
      const PermissionDeniedConfig(
        title: 'Need camera',
        description: 'Tap try again.',
        retryText: 'Try Again',
        skipText: 'Skip',
      ),
    );
    expect(find.byKey(const Key('wizard.denied.retry')), findsOneWidget);
    expect(find.byKey(const Key('wizard.denied.openSettings')), findsNothing);
    expect(find.byKey(const Key('wizard.denied.skip')), findsOneWidget);
  });

  testWidgets('hides open settings when suppressOpenSettings true',
      (tester) async {
    await pumpDenied(
      tester,
      const PermissionDeniedConfig(
        title: 'Camera blocked',
        description: 'Open settings to enable it.',
        openSettingsText: 'Open Settings',
        skipText: 'Skip',
      ),
      suppressOpenSettings: true,
    );
    expect(find.byKey(const Key('wizard.denied.openSettings')), findsNothing);
    expect(find.byKey(const Key('wizard.denied.skip')), findsOneWidget);
  });

  testWidgets('button taps return the right DeniedAction', (tester) async {
    DeniedAction? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                captured = await showDialog<DeniedAction>(
                  context: ctx,
                  builder: (_) => const DeniedDialog(
                    config: PermissionDeniedConfig(
                      title: 'T',
                      description: 'D',
                      openSettingsText: 'Open',
                      skipText: 'Skip',
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wizard.denied.openSettings')));
    await tester.pumpAndSettle();
    expect(captured, DeniedAction.openSettings);
  });
}
