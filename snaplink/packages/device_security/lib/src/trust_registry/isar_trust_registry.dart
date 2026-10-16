import 'package:core_protocol/core_protocol.dart';
import 'package:isar/isar.dart';

import 'package:device_security/src/trust_registry/trust_registry.dart';
import 'package:device_security/src/trust_registry/trust_registry_record.dart';

class IsarTrustRegistry implements ITrustRegistry {
  IsarTrustRegistry(this._isar);

  final Isar _isar;

  @override
  Future<void> delete(String trustedDeviceId) async {
    final record = await _isar.trustRegistryRecords
        .filter()
        .trustedDeviceIdEqualTo(trustedDeviceId)
        .findFirst();
    if (record == null) {
      return;
    }
    await _isar.writeTxn(() => _isar.trustRegistryRecords.delete(record.id));
  }

  @override
  Future<List<TrustedDevice>> getAll() async {
    final records = await _isar.trustRegistryRecords.where().findAll();
    return records.map((record) => record.toDomain()).toList();
  }

  @override
  Future<TrustedDevice?> getByTrustedDeviceId(String trustedDeviceId) async {
    final record = await _isar.trustRegistryRecords
        .filter()
        .trustedDeviceIdEqualTo(trustedDeviceId)
        .findFirst();
    return record?.toDomain();
  }

  @override
  Future<void> revoke(String trustedDeviceId) async {
    final record = await _isar.trustRegistryRecords
        .filter()
        .trustedDeviceIdEqualTo(trustedDeviceId)
        .findFirst();
    if (record == null) {
      return;
    }
    record.revoked = true;
    await _isar.writeTxn(() => _isar.trustRegistryRecords.put(record));
  }

  @override
  Future<void> upsert(TrustedDevice device) async {
    final record = TrustRegistryRecord.fromDomain(device);
    await _isar.writeTxn(() => _isar.trustRegistryRecords.put(record));
  }
}
