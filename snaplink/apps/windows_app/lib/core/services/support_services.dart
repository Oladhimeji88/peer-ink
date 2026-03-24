import 'dart:io';

import 'package:core_protocol/core_protocol.dart';
import 'package:device_security/device_security.dart';

class TrustedSecretVault {
  TrustedSecretVault(this._secureStorage);

  final SecureStorageAdapter _secureStorage;

  Future<void> save(String trustedDeviceId, String secret) {
    return _secureStorage.write(
      key: 'trusted_secret_$trustedDeviceId',
      value: secret,
    );
  }

  Future<String?> read(String trustedDeviceId) {
    return _secureStorage.read('trusted_secret_$trustedDeviceId');
  }

  Future<void> delete(String trustedDeviceId) {
    return _secureStorage.delete('trusted_secret_$trustedDeviceId');
  }
}

class NoopTelemetrySink implements ITelemetrySink {
  @override
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) async {}

  @override
  Future<void> recordEvent(
    String name, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {}
}

class DesktopNotificationService {
  const DesktopNotificationService();

  Future<void> notifyReceiveSuccess(TransferResult result) async {
    stdout.writeln('SNAPLINK received ${result.finalFilename}');
  }
}

