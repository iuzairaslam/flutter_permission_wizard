import 'package:permission_handler/permission_handler.dart';

/// Tiny TTL cache for [PermissionStatus] lookups.
///
/// Why: status queries hit a method channel which, while fast, is not free.
/// During a single wizard flow we may check status three or four times in
/// rapid succession (initial check, post-OS-prompt, on resume from
/// Settings). The cache de-duplicates those reads within a short window.
class PermissionCache {
  final Duration ttl;
  final Map<Permission, _CachedEntry> _entries = {};

  PermissionCache({this.ttl = const Duration(seconds: 2)});

  /// Returns the cached value when fresh, otherwise `null`.
  PermissionStatus? read(Permission permission) {
    final entry = _entries[permission];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.fetchedAt) > ttl) {
      _entries.remove(permission);
      return null;
    }
    return entry.status;
  }

  /// Store a freshly fetched status.
  void write(Permission permission, PermissionStatus status) {
    _entries[permission] = _CachedEntry(status, DateTime.now());
  }

  /// Drop the cached status for [permission].
  void invalidate(Permission permission) {
    _entries.remove(permission);
  }

  /// Drop every cached entry.
  void clear() => _entries.clear();

  /// Convenience: read-through to [getter] when the cache misses.
  Future<PermissionStatus> readOrFetch(
    Permission permission,
    Future<PermissionStatus> Function() getter,
  ) async {
    final cached = read(permission);
    if (cached != null) return cached;
    final fresh = await getter();
    write(permission, fresh);
    return fresh;
  }
}

class _CachedEntry {
  final PermissionStatus status;
  final DateTime fetchedAt;

  const _CachedEntry(this.status, this.fetchedAt);
}
