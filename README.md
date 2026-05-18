# flutter_permission_wizard

<p align="center">
  <img src="doc/cover.png" alt="Permission wizard flow: rationale, system dialog, settings" width="100%" />
</p>

Hey — if you’ve ever shipped permissions in Flutter, you know the drill. [`permission_handler`](https://pub.dev/packages/permission_handler) tells you what the OS thinks… but it doesn’t help you *talk to humans*. Everyone ends up rebuilding the same story:

Explain why you’re asking → show the system sheet → handle “not now” without sounding robotic → send people to Settings when the OS won’t nag them again.

**That whole flow is what this package tries to save you from wiring yourself.**

It rides on `permission_handler` (plus app settings under the hood), stays easy to theme, and you can still test it without juggling twelve phones. On your side it’s “just Dart” — you already handle plist/manifest bits like you always did.

---

## Drop it in

```yaml
dependencies:
  flutter_permission_wizard: ^0.1.3
```

`flutter pub get`, then carry on. Whatever platform strings or manifest lines your permissions need — camera, mic, photos — that doesn’t magically disappear; this just handles the *conversation* with your user.

---

## Start here (honestly, this might be enough)

Paste this, rename things so they sound like *your* app, ship dinner:

```dart
final result = await PermissionWizard.request(
  context: context,
  request: PermissionRequest(
    permission: Permission.camera,
    rationale: PermissionRationale(
      iconData: Icons.camera_alt_rounded,
      title: 'Camera access',
      description: 'We use the camera to scan QR codes and update your profile photo.',
      allowButtonText: 'Continue',
      denyButtonText: 'Not now',
    ),
    deniedConfig: PermissionDeniedConfig(
      title: 'Camera is turned off',
      description: 'Turn camera access on in Settings to use this feature.',
      openSettingsText: 'Open Settings',
      skipText: 'Skip for now',
    ),
  ),
);

switch (result) {
  case GrantedResult():
  case LimitedResult(): // e.g. limited Photos on iOS
    launchCamera();
  case DeniedResult():
    showDegradedMode();
  case RestrictedResult():
    showRestrictedMessage();
  case CancelledResult():
    break;
}
```

One await: friendly heads-up → OS prompt → “oops, here’s how to fix it” if needed → typed result at the end. No judgement if someone taps away.

---

## Pick how you want to drive it

There isn’t one “right” API — depends how your screen is built:

| If you… | Reach for |
| ------- | --------- |
| …just want “when they tap this button, ask nicely” | **`PermissionWizard.request(...)`** |
| …want the UI to react while permission state changes | **`PermissionWizardBuilder`** |
| …fire the flow from somewhere outside the widget tree (BLoC, repo, whatever) | **`PermissionWizardController`** |

**Living inside a widget tree:**

```dart
PermissionWizardBuilder(
  request: PermissionRequest(
    permission: Permission.locationWhenInUse,
    rationale: PermissionRationale(
      title: 'Location',
      description: 'Used to show places near you.',
    ),
  ),
  builder: (context, status, requestPermission) {
    return switch (status) {
      WizardStatus.granted => const MapWidget(),
      WizardStatus.denied => TextButton(
          onPressed: requestPermission,
          child: const Text('Enable location'),
        ),
      WizardStatus.restricted => const RestrictedPlaceholder(),
      _ => const SizedBox.shrink(),
    };
  },
)
```

**Driving it yourself:**

```dart
final controller = PermissionWizardController(
  request: PermissionRequest(permission: Permission.microphone, /* … */),
);

await controller.requestPermission(context);
if (controller.isGranted) {
  // …
}
```

---

## Asking for more than one thing

Camera *and* mic? **`PermissionWizard.requestBatch`** has your back:

- **`BatchStrategy.combined`** — “Here’s why we need both,” then the OS dialogs show up in order. Feels natural when the feature genuinely needs everything.
- **`BatchStrategy.sequential`** — treat each permission like its own mini story. Handy when users might grant one and bail on the other.

```dart
final result = await PermissionWizard.requestBatch(
  context: context,
  request: BatchPermissionRequest(
    strategy: BatchStrategy.combined,
    batchRationale: PermissionRationale(
      title: 'Video calls',
      description: 'We need your camera and microphone for calls.',
      bullets: [
        PermissionBullet(icon: Icons.camera_alt, label: 'Camera'),
        PermissionBullet(icon: Icons.mic, label: 'Microphone'),
      ],
      allowButtonText: 'Allow both',
    ),
    permissions: [
      PermissionRequest(permission: Permission.camera),
      PermissionRequest(permission: Permission.microphone),
    ],
  ),
);

if (result.allGranted) startVideoCall();
```

---

## Make it feel like *your* product

Out of the box it respects **`Theme.of(context)`**, so dark mode and Material 3 mostly Just Work™.

Want more personality? Slap on a **`WizardTheme`** — colors, spacing, chunky buttons, whatever.

Still not enough? You can tuck stuff above/below with **`headerBuilder`** / **`footerBuilder`**, swap individual chunks with slot builders, or go full **`customBuilder`** if you’re picky (no shame).

Quick vibes to start from: **`WizardTheme.compact()`**, **`WizardTheme.expressive()`**, **`WizardTheme.minimal()`** — then **`copyWith`** the bits you care about.

Same screens can show as a centered dialog, a bottom sheet, or full-screen via **`RationaleStyle`** / **`DeniedStyle`** — flip it without rewriting your logic.

---

## iOS vs Android (the boring-but-important bit)

**iOS** likes to make the first “no” stick — so the wizard behaves accordingly. Limited photo library access surfaces as **`LimitedResult`** so you can still do something useful. Provisional notifications are treated as good enough to move forward.

**Android** cares whether the user might still see another prompt or whether you’re in “only Settings can save us” territory — that split is handled for you. Double-check you’re requesting the **`Permission.*`** that matches your **`targetSdkVersion`** (media splits on newer Androids are easy to trip over).

Curious about edge cases — app goes to background mid-dialog, two requests racing, analytics hooks — peek at **`PermissionWizardCallbacks`** and **`PermissionStateMachine`** in the source; the README would turn into a novel if we listed every scenario here.

---

## Testing without borrowing someone’s phone

Hook **`PermissionWizard.debugConfigure`** with a fake checker and **`FakeSettingsLauncher`**, spin up **`PermissionStateMachine`** in plain Dart tests, and sleep better. The **`test/`** folder has plenty of copy-paste fuel.

---

## License

MIT — see **`LICENSE`**.
