import 'package:flutter/material.dart';
import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_permission_wizard/src/ui/dialogs/denied_dialog.dart';
import 'package:flutter_permission_wizard/src/ui/dialogs/rationale_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke tests for the new dynamic dialog customisation surface:
/// per-slot builders (icon/title/description/bullets/actions/header/
/// footer) on [PermissionRationale] and [PermissionDeniedConfig] plus
/// the expanded [WizardTheme] knobs (presets, button heights, action
/// layout, icon container sizing).
void main() {
  Future<void> showRationale(
    WidgetTester tester,
    PermissionRationale rationale, {
    WizardTheme? theme,
  }) async {
    final scopedTheme = theme ?? const WizardTheme();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog(
                  context: ctx,
                  builder: (_) => WizardThemeScope(
                    theme: scopedTheme,
                    child: RationaleDialog(rationale: rationale),
                  ),
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

  testWidgets('rationale headerBuilder + footerBuilder are rendered',
      (tester) async {
    final rationale = PermissionRationale(
      title: 'T',
      description: 'D',
      headerBuilder: (ctx, r) => const Text('HEADER_BADGE'),
      footerBuilder: (ctx, r) => const Text('FINE_PRINT'),
    );
    await showRationale(tester, rationale);
    expect(find.text('HEADER_BADGE'), findsOneWidget);
    expect(find.text('FINE_PRINT'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
  });

  testWidgets('rationale iconBuilder replaces icon section', (tester) async {
    final rationale = PermissionRationale(
      title: 'T',
      description: 'D',
      iconData: Icons.camera_alt,
      iconBuilder: (ctx, r) => const Icon(
        Icons.bolt,
        key: Key('custom-icon'),
        size: 24,
      ),
    );
    await showRationale(tester, rationale);
    expect(find.byKey(const Key('custom-icon')), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsNothing);
  });

  testWidgets(
      'rationale actionsBuilder replaces the action row while preserving '
      'allow/deny callbacks', (tester) async {
    bool allowed = false;
    bool denied = false;
    final rationale = PermissionRationale(
      title: 'T',
      description: 'D',
      actionsBuilder: (ctx, r, onAllow, onDeny) => Row(
        children: [
          ElevatedButton(
            key: const Key('custom-allow'),
            onPressed: () {
              allowed = true;
              onAllow();
            },
            child: const Text('Yes'),
          ),
          ElevatedButton(
            key: const Key('custom-deny'),
            onPressed: () {
              denied = true;
              onDeny();
            },
            child: const Text('No'),
          ),
        ],
      ),
    );
    await showRationale(tester, rationale);
    expect(find.byKey(const Key('wizard.rationale.allow')), findsNothing);
    await tester.tap(find.byKey(const Key('custom-allow')));
    await tester.pumpAndSettle();
    expect(allowed, isTrue);
    expect(denied, isFalse);
  });

  testWidgets('WizardTheme.compact preset shrinks padding + buttons',
      (tester) async {
    const rationale = PermissionRationale(
      title: 'Compact',
      description: 'Body',
    );
    await showRationale(
      tester,
      rationale,
      theme: WizardTheme.compact(),
    );
    final allowSize =
        tester.getSize(find.byKey(const Key('wizard.rationale.allow')));
    expect(allowSize.height, 44);
  });

  testWidgets('WizardTheme.expressive preset enlarges the icon container',
      (tester) async {
    const rationale = PermissionRationale(
      title: 'Big',
      description: 'Body',
      iconData: Icons.camera_alt,
    );
    await showRationale(
      tester,
      rationale,
      theme: WizardTheme.expressive(),
    );
    final iconHostSize = tester.getSize(find.byIcon(Icons.camera_alt));
    // Default expressive iconSize is 40 — the Icon widget itself is 40 dp,
    // wrapped in an 80×80 container.
    expect(iconHostSize.height, 40);
    expect(iconHostSize.width, 40);
  });

  testWidgets('WizardTheme.copyWith only overrides supplied fields',
      (tester) async {
    const base = WizardTheme(
      iconColor: Color(0xFFAA0000),
      sectionSpacing: 20,
    );
    final next = base.copyWith(iconColor: const Color(0xFF00FF00));
    expect(next.iconColor, const Color(0xFF00FF00));
    expect(next.sectionSpacing, 20);
  });

  testWidgets('WizardTheme.mergeWith — other wins on conflicts',
      (tester) async {
    const base = WizardTheme(
      primaryColor: Color(0xFFAAAAAA),
      sectionSpacing: 10,
    );
    const overlay = WizardTheme(primaryColor: Color(0xFF112233));
    final merged = base.mergeWith(overlay);
    expect(merged.primaryColor, const Color(0xFF112233));
    expect(merged.sectionSpacing, 10);
  });

  testWidgets('denied dialog renders both Open Settings AND Retry buttons '
      'when both labels are set', (tester) async {
    DeniedAction? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<DeniedAction>(
                  context: ctx,
                  builder: (_) => const DeniedDialog(
                    config: PermissionDeniedConfig(
                      title: 'Denied',
                      description: 'Try one of these:',
                      openSettingsText: 'Open Settings',
                      retryText: 'Try Again',
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
    expect(find.byKey(const Key('wizard.denied.openSettings')), findsOneWidget);
    expect(find.byKey(const Key('wizard.denied.retry')), findsOneWidget);
    expect(find.byKey(const Key('wizard.denied.skip')), findsOneWidget);
    await tester.tap(find.byKey(const Key('wizard.denied.retry')));
    await tester.pumpAndSettle();
    expect(result, DeniedAction.retry);
  });

  testWidgets('denied dialog descriptionBuilder slot wins over description '
      'text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => DeniedDialog(
                  config: PermissionDeniedConfig(
                    title: 'Denied',
                    description: 'Original',
                    descriptionBuilder: (ctx, c) => const Text('REPLACED'),
                  ),
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
    expect(find.text('REPLACED'), findsOneWidget);
    expect(find.text('Original'), findsNothing);
  });
}
