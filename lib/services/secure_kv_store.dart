import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Simple key-value secret store interface.
///
/// On platforms where Keychain/Keystore works out of the box, we delegate to
/// `flutter_secure_storage`. On macOS, ad-hoc code signing without an Apple
/// Developer Team often fails Keychain Services with `errSecMissingEntitlement`
/// (-34018), so we fall back to a JSON file inside the app's support directory.
/// This file is owned by the user account and stays out of cloud sync. For
/// production macOS distribution, replace this with a properly provisioned
/// keychain-backed implementation.
abstract class SecureKvStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();

  static Future<SecureKvStore> create() async {
    if (!kIsWeb && Platform.isMacOS) {
      return _FileKvStore.init();
    }
    return _KeychainKvStore();
  }

  /// In-memory store, primarily for tests.
  factory SecureKvStore.inMemory([Map<String, String>? initial]) =
      _MemoryKvStore;
}

class _MemoryKvStore implements SecureKvStore {
  final Map<String, String> _data;
  _MemoryKvStore([Map<String, String>? initial])
      : _data = Map<String, String>.from(initial ?? const <String, String>{});

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }
}

class _KeychainKvStore implements SecureKvStore {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

class _FileKvStore implements SecureKvStore {
  final File _file;
  final Map<String, String> _cache;

  _FileKvStore._(this._file, this._cache);

  static Future<_FileKvStore> init() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final file = File('${dir.path}/lenker_secure_store.json');
    Map<String, String> cache = <String, String>{};
    if (await file.exists()) {
      try {
        final raw = await file.readAsString();
        if (raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          cache = decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
        }
      } catch (_) {
        // Corrupt store; start fresh rather than crashing the app.
        cache = <String, String>{};
      }
    }
    return _FileKvStore._(file, cache);
  }

  Future<void> _flush() async {
    await _file.writeAsString(jsonEncode(_cache), flush: true);
  }

  @override
  Future<String?> read(String key) async => _cache[key];

  @override
  Future<void> write(String key, String value) async {
    _cache[key] = value;
    await _flush();
  }

  @override
  Future<void> delete(String key) async {
    _cache.remove(key);
    await _flush();
  }

  @override
  Future<void> deleteAll() async {
    _cache.clear();
    await _flush();
  }
}
