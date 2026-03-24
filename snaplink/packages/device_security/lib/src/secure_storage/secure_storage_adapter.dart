import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorageAdapter {
  Future<void> write({required String key, required String value});
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<Map<String, String>> readAll();
}

class FlutterSecureStorageAdapter implements SecureStorageAdapter {
  FlutterSecureStorageAdapter({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);
}

