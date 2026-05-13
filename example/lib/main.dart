import 'package:flutter/material.dart';
import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permission Wizard Demo',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6750A4),
      ),
      home: const DemoHome(),
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});
  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  String _lastResult = '—';

  Future<void> _requestCamera() async {
    final result = await PermissionWizard.request(
      context: context,
      request: const PermissionRequest(
        permission: Permission.camera,
        rationale: PermissionRationale(
          iconData: Icons.camera_alt_rounded,
          title: 'Camera Access',
          description:
              'We use the camera to let you scan QR codes and take profile photos.',
          allowButtonText: 'Allow Camera',
          denyButtonText: 'Not Now',
        ),
        deniedConfig: PermissionDeniedConfig(
          iconData: Icons.camera_alt_outlined,
          title: 'Camera is off',
          description:
              'To use this feature, turn on camera access in your settings.',
          retryText: 'Try Again',
          skipText: 'Skip for now',
        ),
        permanentlyDeniedConfig: PermissionDeniedConfig(
          iconData: Icons.camera_alt_outlined,
          title: 'Camera is blocked',
          description:
              'Camera access was permanently denied. Open settings to enable it.',
          openSettingsText: 'Open Settings',
          skipText: 'Skip for now',
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _lastResult = 'Camera → ${_describe(result)}');
  }

  Future<void> _requestLocationBuilder() async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LocationDemoPage()),
    );
  }

  Future<void> _requestMicWithController() async {
    final controller = PermissionWizardController(
      request: const PermissionRequest(
        permission: Permission.microphone,
        rationale: PermissionRationale(
          iconData: Icons.mic,
          title: 'Microphone',
          description: 'We need your microphone for voice messages.',
          allowButtonText: 'Allow Microphone',
          denyButtonText: 'Not Now',
          style: RationaleStyle.bottomSheet,
        ),
      ),
    );
    controller.stream.listen((status) {
      debugPrint('Mic permission status → $status');
    });
    final result = await controller.requestPermission(context);
    controller.dispose();
    if (!mounted) return;
    setState(() => _lastResult = 'Microphone → ${_describe(result)}');
  }

  Future<void> _requestBatchVideoCall() async {
    final result = await PermissionWizard.requestBatch(
      context: context,
      request: const BatchPermissionRequest(
        strategy: BatchStrategy.combined,
        batchRationale: PermissionRationale(
          iconData: Icons.video_call,
          title: 'Video Calling Needs Two Things',
          description:
              'To make video calls, the app needs both your camera and microphone.',
          allowButtonText: 'Allow Both',
          denyButtonText: 'Not Now',
          bullets: [
            PermissionBullet(
              icon: Icons.camera_alt,
              label: 'Camera',
              sublabel: 'For video',
            ),
            PermissionBullet(
              icon: Icons.mic,
              label: 'Microphone',
              sublabel: 'For audio',
            ),
          ],
        ),
        permissions: [
          PermissionRequest(permission: Permission.camera),
          PermissionRequest(permission: Permission.microphone),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _lastResult = 'Batch → ${result.allGranted ? 'all granted' : 'partial: '
              '${result.grantedPermissions.length}/${result.results.length}'}';
    });
  }

  String _describe(PermissionWizardResult r) => switch (r) {
        GrantedResult() => 'granted',
        LimitedResult() => 'limited (iOS Photos)',
        DeniedResult(:final isPermanent) =>
          isPermanent ? 'denied (permanent)' : 'denied (soft)',
        RestrictedResult() => 'restricted',
        CancelledResult(:final reason) => 'cancelled ($reason)',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permission Wizard Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _requestCamera,
              child: const Text('Static API → Camera (dialog rationale)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _requestLocationBuilder,
              child: const Text('Builder widget → Location'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _requestMicWithController,
              child: const Text('Controller → Microphone (sheet rationale)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _requestBatchVideoCall,
              child: const Text('Batch combined → Camera + Microphone'),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Last result: $_lastResult',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationDemoPage extends StatelessWidget {
  const LocationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Builder Demo')),
      body: PermissionWizardBuilder(
        request: const PermissionRequest(
          permission: Permission.locationWhenInUse,
          rationale: PermissionRationale(
            iconData: Icons.place,
            title: 'Location for Nearby Results',
            description: 'We use your location to show restaurants near you.',
            allowButtonText: 'Allow Location',
            denyButtonText: 'Skip',
            style: RationaleStyle.fullScreen,
          ),
          permanentlyDeniedConfig: PermissionDeniedConfig(
            iconData: Icons.location_off,
            title: 'Location off',
            description: 'Open settings to enable location.',
            openSettingsText: 'Open Settings',
            skipText: 'Skip',
            style: DeniedStyle.fullScreen,
          ),
        ),
        builder: (context, status, requestPermission) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForStatus(status),
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Status: ${status.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  if (status != WizardStatus.granted &&
                      status != WizardStatus.limited)
                    FilledButton(
                      onPressed: () => requestPermission(),
                      child: const Text('Enable Location'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconForStatus(WizardStatus status) => switch (status) {
        WizardStatus.granted || WizardStatus.limited => Icons.place,
        WizardStatus.denied => Icons.location_off,
        WizardStatus.restricted => Icons.lock,
        _ => Icons.help_outline,
      };
}
