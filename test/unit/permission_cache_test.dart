import 'package:flutter_permission_wizard/src/core/permission_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('PermissionCache', () {
    test('read returns null on miss', () {
      final cache = PermissionCache();
      expect(cache.read(Permission.camera), isNull);
    });

    test('write then read returns value', () {
      final cache = PermissionCache();
      cache.write(Permission.camera, PermissionStatus.granted);
      expect(cache.read(Permission.camera), PermissionStatus.granted);
    });

    test('TTL expiry evicts entry', () async {
      final cache = PermissionCache(ttl: const Duration(milliseconds: 50));
      cache.write(Permission.camera, PermissionStatus.granted);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(cache.read(Permission.camera), isNull);
    });

    test('invalidate removes entry', () {
      final cache = PermissionCache();
      cache.write(Permission.camera, PermissionStatus.denied);
      cache.invalidate(Permission.camera);
      expect(cache.read(Permission.camera), isNull);
    });

    test('clear drops everything', () {
      final cache = PermissionCache();
      cache.write(Permission.camera, PermissionStatus.granted);
      cache.write(Permission.microphone, PermissionStatus.denied);
      cache.clear();
      expect(cache.read(Permission.camera), isNull);
      expect(cache.read(Permission.microphone), isNull);
    });

    test('readOrFetch caches the result', () async {
      final cache = PermissionCache();
      var calls = 0;
      Future<PermissionStatus> fetch() async {
        calls += 1;
        return PermissionStatus.granted;
      }

      final first = await cache.readOrFetch(Permission.camera, fetch);
      final second = await cache.readOrFetch(Permission.camera, fetch);
      expect(first, PermissionStatus.granted);
      expect(second, PermissionStatus.granted);
      expect(calls, 1);
    });
  });
}
