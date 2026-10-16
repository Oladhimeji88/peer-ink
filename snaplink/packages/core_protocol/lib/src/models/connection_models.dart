import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core_protocol/src/enums/protocol_enums.dart';
import 'package:core_protocol/src/models/app_models.dart';

part 'connection_models.freezed.dart';
part 'connection_models.g.dart';

@freezed
class PairingSession with _$PairingSession {
  const factory PairingSession({
    required String sessionId,
    required String oneTimeToken,
    required DateTime expiresAt,
    required String desktopDeviceId,
    required String desktopName,
    required String localIp,
    required int port,
    required String tlsCertSha256,
    required bool used,
    required Map<String, bool> capabilityFlags,
  }) = _PairingSession;

  factory PairingSession.fromJson(Map<String, dynamic> json) =>
      _$PairingSessionFromJson(json);
}

@freezed
class PairingQrPayload with _$PairingQrPayload {
  const factory PairingQrPayload({
    required int protocolVersion,
    required String sessionId,
    required String oneTimePairingToken,
    required String desktopDeviceId,
    required String desktopName,
    required String localIp,
    required int port,
    required DateTime expiresAt,
    required String tlsCertSha256,
    required Map<String, bool> capabilityFlags,
  }) = _PairingQrPayload;

  factory PairingQrPayload.fromJson(Map<String, dynamic> json) =>
      _$PairingQrPayloadFromJson(json);
}

@freezed
class ActiveConnection with _$ActiveConnection {
  const factory ActiveConnection({
    required String connectionId,
    required String trustedDeviceId,
    required String remoteHost,
    required int remotePort,
    required DateTime connectedAt,
    required ConnectionHealthState healthState,
    required int lastRoundTripMs,
    required bool authenticated,
    required DeviceInfo remoteDevice,
  }) = _ActiveConnection;

  factory ActiveConnection.fromJson(Map<String, dynamic> json) =>
      _$ActiveConnectionFromJson(json);
}

@freezed
class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String authSessionId,
    required String trustedDeviceId,
    required DateTime issuedAt,
    required DateTime expiresAt,
    required String accessTokenHash,
    required String refreshSecretHash,
    required String certificateSha256,
  }) = _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);
}
