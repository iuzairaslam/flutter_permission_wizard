import 'package:flutter/material.dart';
import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_permission_wizard/src/ui/dialogs/denied_dialog.dart';
import 'package:flutter_permission_wizard/src/ui/dialogs/rationale_dialog.dart';
import 'package:flutter_permission_wizard/src/ui/screens/denied_full_screen.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({
  required Widget child,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: const Color(0xFF6750A4),
    ),
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  testWidgets('golden: rationale dialog (light)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: const RationaleDialog(
          rationale: PermissionRationale(
            iconData: Icons.camera_alt_rounded,
            title: 'Camera Access',
            description:
                'We need your camera to let you scan QR codes and take profile photos.',
            allowButtonText: 'Allow Camera',
            denyButtonText: 'Not Now',
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Dialog),
      matchesGoldenFile('golden/rationale_dialog_light.png'),
    );
  });

  testWidgets('golden: rationale dialog (dark)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        brightness: Brightness.dark,
        child: const RationaleDialog(
          rationale: PermissionRationale(
            iconData: Icons.camera_alt_rounded,
            title: 'Camera Access',
            description:
                'We need your camera to let you scan QR codes and take profile photos.',
            allowButtonText: 'Allow Camera',
            denyButtonText: 'Not Now',
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Dialog),
      matchesGoldenFile('golden/rationale_dialog_dark.png'),
    );
  });

  testWidgets('golden: denied dialog (light)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: const DeniedDialog(
          config: PermissionDeniedConfig(
            iconData: Icons.camera_alt_outlined,
            title: 'Camera is off',
            description:
                'To use this feature, turn on camera access in your settings.',
            openSettingsText: 'Open Settings',
            skipText: 'Skip for now',
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Dialog),
      matchesGoldenFile('golden/denied_dialog_light.png'),
    );
  });

  testWidgets('golden: denied full-screen (light)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: const DeniedFullScreen(
          config: PermissionDeniedConfig(
            iconData: Icons.camera_alt_outlined,
            title: 'Camera blocked',
            description:
                'Camera access was permanently denied. Open settings to enable it.',
            openSettingsText: 'Open Settings',
            skipText: 'Skip',
            style: DeniedStyle.fullScreen,
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold).last,
      matchesGoldenFile('golden/denied_full_screen_light.png'),
    );
  });
}
