import 'package:core_protocol/core_protocol.dart';

abstract class ITrustRegistry {
  Future<List<TrustedDevice>> getAll();
  Future<TrustedDevice?> getByTrustedDeviceId(String trustedDeviceId);
  Future<void> upsert(TrustedDevice device);
  Future<void> revoke(String trustedDeviceId);
  Future<void> delete(String trustedDeviceId);
}

