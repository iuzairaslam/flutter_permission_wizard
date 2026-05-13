import 'package:flutter/material.dart';
import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_permission_wizard/src/ui/dialogs/rationale_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester,
    PermissionRationale rationale,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog(
                  context: ctx,
                  builder: (_) => RationaleDialog(rationale: rationale),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders title, description, and buttons', (tester) async {
    await pumpDialog(
      tester,
      const PermissionRationale(
        iconData: Icons.camera_alt,
        title: 'Camera',
        description: 'We need the camera for QR codes.',
        allowButtonText: 'Allow Camera',
        denyButtonText: 'Not Now',
      ),
    );
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('We need the camera for QR codes.'), findsOneWidget);
    expect(find.text('Allow Camera'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
  });

  testWidgets('renders bullets when provided', (tester) async {
    await pumpDialog(
      tester,
      const PermissionRationale(
        title: 'Video',
        description: 'For video calls.',
        bullets: [
          PermissionBullet(icon: Icons.mic, label: 'Microphone'),
          PermissionBullet(icon: Icons.camera_alt, label: 'Camera'),
        ],
      ),
    );
    expect(find.text('Microphone'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
  });

  testWidgets('allow / deny actions pop with the correct result',
      (tester) async {
    RationaleAction? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                captured = await showDialog<RationaleAction>(
                  context: ctx,
                  builder: (_) => const RationaleDialog(
                    rationale: PermissionRationale(
                      title: 'T',
                      description: 'D',
                      allowButtonText: 'A',
                      denyButtonText: 'B',
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
    await tester.tap(find.byKey(const Key('wizard.rationale.allow')));
    await tester.pumpAndSettle();
    expect(captured, RationaleAction.allow);
  });

  testWidgets('deny button returns RationaleAction.deny', (tester) async {
    RationaleAction? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                captured = await showDialog<RationaleAction>(
                  context: ctx,
                  builder: (_) => const RationaleDialog(
                    rationale: PermissionRationale(
                      title: 'T',
                      description: 'D',
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
    await tester.tap(find.byKey(const Key('wizard.rationale.deny')));
    await tester.pumpAndSettle();
    expect(captured, RationaleAction.deny);
  });
}
