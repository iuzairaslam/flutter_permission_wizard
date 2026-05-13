import 'package:flutter_permission_wizard/flutter_permission_wizard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryWizardStorage', () {
    test('returns false for unknown keys', () async {
      final store = InMemoryWizardStorage();
      expect(await store.getBool('nope'), isFalse);
    });

    test('round-trips set/get', () async {
      final store = InMemoryWizardStorage();
      await store.setBool('camera', true);
      expect(await store.getBool('camera'), isTrue);
      await store.setBool('camera', false);
      expect(await store.getBool('camera'), isFalse);
    });

    test('clear empties the storage', () async {
      final store = InMemoryWizardStorage();
      await store.setBool('camera', true);
      store.clear();
      expect(await store.getBool('camera'), isFalse);
    });
  });

  group('Android checker (storage interactions)', () {
    test('markAsAsked / hasBeenAskedBefore round trips', () async {
      final storage = InMemoryWizardStorage();
      final checker = AndroidPermissionChecker(storage: storage);
      expect(await checker.hasBeenAskedBefore(Permission.camera), isFalse);
      await checker.markAsAsked(Permission.camera);
      expect(await checker.hasBeenAskedBefore(Permission.camera), isTrue);
    });

    test('supportsLimited is false on Android', () {
      expect(AndroidPermissionChecker().supportsLimited, isFalse);
    });
  });

  group('iOS checker (storage interactions)', () {
    test('markAsAsked / hasBeenAskedBefore round trips', () async {
      final storage = InMemoryWizardStorage();
      final checker = IosPermissionChecker(storage: storage);
      expect(await checker.hasBeenAskedBefore(Permission.camera), isFalse);
      await checker.markAsAsked(Permission.camera);
      expect(await checker.hasBeenAskedBefore(Permission.camera), isTrue);
    });

    test('supportsLimited is true on iOS', () {
      expect(IosPermissionChecker().supportsLimited, isTrue);
    });
  });
}
