/// Declarative, state-machine-driven permission flow wizard for Flutter.
///
/// Build a single, themeable, end-to-end UX around `permission_handler`
/// covering rationale dialogs, soft/permanent denial, restricted devices,
/// and the round-trip through the Settings app.
///
/// See the [PermissionWizard] static class for the imperative entry point,
/// [PermissionWizardBuilder] for the reactive widget, and
/// [PermissionWizardController] for advanced use cases.
library;

// Public API ---------------------------------------------------------------

export 'package:permission_handler/permission_handler.dart' show Permission, PermissionStatus;

// Models
export 'src/models/batch_permission_request.dart';
export 'src/models/enums.dart';
export 'src/models/permission_bullet.dart';
export 'src/models/permission_denied_config.dart';
export 'src/models/permission_rationale.dart';
export 'src/models/permission_request.dart';
export 'src/models/permission_restricted_config.dart';
export 'src/models/permission_wizard_callbacks.dart';
export 'src/models/permission_wizard_result.dart';
export 'src/models/wizard_theme.dart';

// State
export 'src/state/wizard_status.dart' show WizardStatus;

// Platform layer (exported so power users can implement custom checkers)
export 'src/platform/platform_permission_checker.dart'
    show
        PlatformPermissionChecker,
        RequestOutcome,
        WizardPreferencesStorage,
        InMemoryWizardStorage;
export 'src/platform/android_permission_checker.dart';
export 'src/platform/ios_permission_checker.dart';

// Core
export 'src/core/app_lifecycle_observer.dart'
    show AppLifecycleObserver, AppLifecycleEvent;
export 'src/core/permission_cache.dart' show PermissionCache;
export 'src/core/permission_wizard.dart' show PermissionWizard;
export 'src/core/permission_wizard_controller.dart';
export 'src/core/settings_launcher.dart' show SettingsLauncher;

// UI widgets
export 'src/ui/widgets/permission_wizard_builder.dart';
export 'src/ui/widgets/wizard_theme_scope.dart'
    show WizardThemeScope, ResolvedWizardTheme;
// Default slot widgets — reusable building blocks for custom builders.
export 'src/ui/widgets/wizard_slots.dart'
    show
        DefaultRationaleIcon,
        DefaultRationaleTitle,
        DefaultRationaleDescription,
        DefaultRationaleBullets,
        DefaultRationaleActions,
        DefaultDeniedIcon,
        DefaultDeniedTitle,
        DefaultDeniedDescription,
        DefaultDeniedActions;
export 'src/ui/widgets/permission_bullet_item.dart' show PermissionBulletItem;
