import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result equality', () {
    test('GrantedResult instances are equal', () {
      expect(const GrantedResult(), const GrantedResult());
      expect(const GrantedResult().hashCode, const GrantedResult().hashCode);
    });
    test('DeniedResult differs on isPermanent', () {
      expect(
        const DeniedResult(isPermanent: true),
        const DeniedResult(isPermanent: true),
      );
      expect(
        const DeniedResult(isPermanent: true) ==
            const DeniedResult(isPermanent: false),
        isFalse,
      );
    });
    test('CancelledResult differs on reason', () {
      expect(
        const CancelledResult(reason: 'a'),
        const CancelledResult(reason: 'a'),
      );
      expect(
        const CancelledResult(reason: 'a') ==
            const CancelledResult(reason: 'b'),
        isFalse,
      );
    });

    test('sealed switch is exhaustive at compile time', () {
      // If any new subtype is added without an arm here this will fail to
      // compile — exactly the property we want.
      String describe(PermissionWizardResult r) => switch (r) {
            GrantedResult() => 'granted',
            LimitedResult() => 'limited',
            DeniedResult() => 'denied',
            RestrictedResult() => 'restricted',
            CancelledResult() => 'cancelled',
          };
      expect(describe(const GrantedResult()), 'granted');
      expect(describe(const LimitedResult()), 'limited');
      expect(describe(const DeniedResult(isPermanent: true)), 'denied');
      expect(describe(const RestrictedResult()), 'restricted');
      expect(describe(const CancelledResult(reason: 'x')), 'cancelled');
    });
  });

  group('BatchPermissionWizardResult', () {
    test('allGranted true when every entry granted/limited', () {
      final result = BatchPermissionWizardResult({
        Permission.camera: const GrantedResult(),
        Permission.photos: const LimitedResult(),
      });
      expect(result.allGranted, isTrue);
      expect(result.anyGranted, isTrue);
      expect(result.grantedPermissions, contains(Permission.camera));
      expect(result.deniedPermissions, isEmpty);
    });

    test('allGranted false when any denied/cancelled', () {
      final result = BatchPermissionWizardResult({
        Permission.camera: const GrantedResult(),
        Permission.microphone: const DeniedResult(isPermanent: true),
      });
      expect(result.allGranted, isFalse);
      expect(result.anyGranted, isTrue);
      expect(result.deniedPermissions, [Permission.microphone]);
    });

    test('anyGranted false when none granted', () {
      final result = BatchPermissionWizardResult({
        Permission.camera: const DeniedResult(isPermanent: false),
        Permission.microphone: const CancelledResult(reason: 'x'),
      });
      expect(result.allGranted, isFalse);
      expect(result.anyGranted, isFalse);
    });
  });
}
