import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core_protocol/src/enums/protocol_enums.dart';

part 'app_models.freezed.dart';
part 'app_models.g.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    required String saveDirectory,
    required bool autoAcceptTrustedDevices,
    required String filenamePattern,
    required int compressionQuality,
    required int listenerPort,
    required bool notificationsEnabled,
    required bool receiveSoundEnabled,
    required bool startOnLaunch,
    required bool reviewBeforeSend,
    required bool rememberTrustedDevices,
    required bool saveOptimizedCopy,
    required String transferModePreference,
    required int maxUploadBytes,
  }) = _AppSettings;

  factory AppSettings.defaults() => const AppSettings(
        saveDirectory: '',
        autoAcceptTrustedDevices: true,
        filenamePattern: '{deviceName}_{yyyyMMdd_HHmmss}_{shortId}.jpg',
        compressionQuality: 88,
        listenerPort: 42817,
        notificationsEnabled: true,
        receiveSoundEnabled: true,
        startOnLaunch: false,
        reviewBeforeSend: false,
        rememberTrustedDevices: true,
        saveOptimizedCopy: false,
        transferModePreference: 'wifi_local',
        maxUploadBytes: 50 * 1024 * 1024,
      );

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}

@freezed
class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String deviceId,
    required String deviceName,
    required TrustedDevicePlatform platform,
    required String appVersion,
    required String osVersion,
    String? localIp,
    Map<String, bool>? capabilities,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
}

@freezed
class TrustedDevice with _$TrustedDevice {
  const factory TrustedDevice({
    required String trustedDeviceId,
    required String desktopDeviceId,
    required String deviceName,
    required String nickname,
    required TrustedDevicePlatform platform,
    required DateTime pairedAt,
    required DateTime lastConnectedAt,
    required String lastKnownHost,
    required int lastKnownPort,
    required String certificateSha256,
    required bool revoked,
    required bool autoReconnect,
  }) = _TrustedDevice;

  factory TrustedDevice.fromJson(Map<String, dynamic> json) =>
      _$TrustedDeviceFromJson(json);
}

@freezed
class ReceiveLogEntry with _$ReceiveLogEntry {
  const factory ReceiveLogEntry({
    required String id,
    required DateTime timestamp,
    required ReceiveLogLevel level,
    required String message,
    String? transferJobId,
    String? sourceDeviceName,
    Map<String, dynamic>? details,
  }) = _ReceiveLogEntry;

  factory ReceiveLogEntry.fromJson(Map<String, dynamic> json) =>
      _$ReceiveLogEntryFromJson(json);
}
