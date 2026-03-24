import 'package:core_protocol/core_protocol.dart';
import 'package:isar/isar.dart';

part 'trust_registry_record.g.dart';

@collection
class TrustRegistryRecord {
  TrustRegistryRecord();

  Id id = Isar.autoIncrement;

  late String trustedDeviceId;
  late String desktopDeviceId;
  late String deviceName;
  late String nickname;
  late String platform;
  late DateTime pairedAt;
  late DateTime lastConnectedAt;
  late String lastKnownHost;
  late int lastKnownPort;
  late String certificateSha256;
  late bool revoked;
  late bool autoReconnect;

  TrustedDevice toDomain() => TrustedDevice(
        trustedDeviceId: trustedDeviceId,
        desktopDeviceId: desktopDeviceId,
        deviceName: deviceName,
        nickname: nickname,
        platform: TrustedDevicePlatform.values.firstWhere(
          (value) => value.name == platform,
          orElse: () => TrustedDevicePlatform.unknown,
        ),
        pairedAt: pairedAt,
        lastConnectedAt: lastConnectedAt,
        lastKnownHost: lastKnownHost,
        lastKnownPort: lastKnownPort,
        certificateSha256: certificateSha256,
        revoked: revoked,
        autoReconnect: autoReconnect,
      );

  static TrustRegistryRecord fromDomain(TrustedDevice device) {
    final record = TrustRegistryRecord();
    record.trustedDeviceId = device.trustedDeviceId;
    record.desktopDeviceId = device.desktopDeviceId;
    record.deviceName = device.deviceName;
    record.nickname = device.nickname;
    record.platform = device.platform.name;
    record.pairedAt = device.pairedAt;
    record.lastConnectedAt = device.lastConnectedAt;
    record.lastKnownHost = device.lastKnownHost;
    record.lastKnownPort = device.lastKnownPort;
    record.certificateSha256 = device.certificateSha256;
    record.revoked = device.revoked;
    record.autoReconnect = device.autoReconnect;
    return record;
  }
}

