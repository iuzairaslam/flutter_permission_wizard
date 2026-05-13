# Changelog

## 0.1.1 — Stability hardening

### Added
- `PermissionWizardController.cancel()` — abort an in-flight wizard run
  from outside the widget tree. Resolves the pending future with
  `CancelledResult(reason: 'cancelled_by_host')`.
- `PermissionWizardController.isBusy` — true while a wizard run is in
  flight.
- `WizardCancelReason.cancelledByHost` and
  `WizardCancelReason.internalError` constants for the two new
  termination paths.
- `PermissionWizard.resolveChecker()`, `resolveLifecycle()`,
  `resolveSettingsLauncher()`, and the `cache` getter — exposed so the
  controller and other power-user integrations can re-use the same
  resolution logic the static entry point uses (and therefore honour
  any `debugConfigure`-installed fakes).
- Edge-case test suite (`test/widget/edge_cases_test.dart`) covering
  concurrent requests, app-backgrounded during rationale, limited /
  provisional grants, `maxRetryAttempts: 0`, host-driven cancellation,
  and dispose-during-run.

### Changed
- `PermissionWizardBuilder` now routes status reads through the
  platform checker resolved by `PermissionWizard`, so any
  `debugConfigure`-installed fake is honoured during tests and during
  composable testing.
- `PermissionWizard.request` (and `requestBatch`) now trap unexpected
  exceptions raised inside the wizard, report them via
  `FlutterError.reportError`, and surface a
  `CancelledResult(reason: 'internal_error')` instead of propagating —
  the wizard now contractually never throws to its caller.
- `WizardSession.dispose()` is idempotent; calling it while a run is in
  flight cancels the run and unwinds cleanly.
- `PermissionRequest` constructor asserts `maxRetryAttempts >= 0`.
- `AppLifecycleObserver` no longer adds events to a closed broadcast
  controller, eliminating a latent crash path in test tear-down.
- `PermissionStateMachine.awaitingResume` now also accepts
  `appBackgrounded` (transitioning to `cancelled`), so a settings
  round-trip that's interrupted by another background event doesn't
  leave the FSM stuck.

### Fixed
- `PermissionWizardController` no longer leaks an `AppLifecycleObserver`
  when constructed with a `checkerOverride` but no `lifecycleOverride`.
  Observers spawned by the controller are detached in `dispose`.
- `PermissionWizardController._emit` is now disposal-safe — late stream
  events do not throw after the controller is disposed.
- Settings-launcher exceptions are now caught, reported via
  `FlutterError.reportError`, and the round-trip waiter is unblocked
  immediately (returns `DeniedResult(isPermanent: true)` rather than
  hanging forever).
- Removed the dead `_DefaultPlatformChecker`/`_LocalResolver`
  indirection inside the controller in favour of the new
  `PermissionWizard.resolveChecker()` helper.

## 0.1.0 — Initial release

First public release of `flutter_permission_wizard`.

### Added
- `PermissionWizard.request()` — single-permission imperative wizard API.
- `PermissionWizard.requestBatch()` — batch wizards with `combined` and
  `sequential` strategies, with shared rationale support.
- `PermissionWizardBuilder` — reactive widget that exposes the current
  `WizardStatus` plus a `requestPermission` callback.
- `PermissionWizardController` — `ChangeNotifier`-based controller for
  triggering wizards outside the widget tree, with a `Stream<WizardStatus>`.
- `PermissionStateMachine` — pure FSM with full event history, used
  internally and unit-testable end-to-end.
- Platform abstraction (`PlatformPermissionChecker`) with concrete
  `IosPermissionChecker` and `AndroidPermissionChecker` implementations
  handling iOS first-denial-is-permanent, Android
  `shouldShowRequestPermissionRationale`, `limited` / `provisional`
  Photos / Notification statuses, and the location-always-needs-when-in-use
  chained flow.
- Sealed `PermissionWizardResult` (`Granted`, `Limited`, `Denied`,
  `Restricted`, `Cancelled`) so callers must exhaustively handle every
  outcome at compile time.
- `BatchPermissionWizardResult` with `allGranted`, `anyGranted`,
  `grantedPermissions`, and `deniedPermissions`.
- Three configurable presentation styles for both rationale and denied
  states (`dialog`, `bottomSheet`, `fullScreen`).
- Optional `customBuilder` escape hatch on both rationale and denied
  configs for fully bespoke UI while keeping the FSM in charge of flow
  logic.
- `WizardTheme` for fine-grained theming; full Material 3 / dark-mode
  inheritance from the ambient `ThemeData` by default.
- Settings round-trip detection via `AppLifecycleObserver`, with a
  configurable `settingsReturnDelay`.
- Internal `RequestQueue` to serialise concurrent wizard calls.
- TTL-based `PermissionCache` to de-duplicate status lookups during a
  single flow.
- `PermissionWizard.debugConfigure()` / `debugReset()` for ergonomic
  testing: inject a fake `PlatformPermissionChecker`, custom lifecycle
  observer, or fake settings launcher.
- Observer-only callback set (`PermissionWizardCallbacks`) covering every
  meaningful step of the flow — perfect for analytics wiring.

### Tested
- 80 unit, widget, and golden tests covering: every FSM transition, the
  permission cache, request-queue serialisation, sealed-result equality,
  every UI surface (rationale / denied dialogs, bottom sheets,
  full-screen), the controller lifecycle, the builder widget, batch flows
  in both strategies, soft / permanent denial paths, Settings
  round-tripping, retry budgets, callback ordering, concurrent requests,
  app-backgrounded interrupts, limited / provisional grants,
  `maxRetryAttempts: 0`, host-driven cancellation, and dispose-during-run.
