import 'package:core_protocol/core_protocol.dart';

class MobileConnectionState {
  const MobileConnectionState({
    required this.status,
    this.activeConnection,
    this.currentDevice,
    this.lastError,
    this.lastHealth = ConnectionHealthState.offline,
  });

  factory MobileConnectionState.initial() => const MobileConnectionState(
        status: AppConnectionStatus.idle,
      );

  final AppConnectionStatus status;
  final ActiveConnection? activeConnection;
  final TrustedDevice? currentDevice;
  final String? lastError;
  final ConnectionHealthState lastHealth;

  MobileConnectionState copyWith({
    AppConnectionStatus? status,
    ActiveConnection? activeConnection,
    TrustedDevice? currentDevice,
    String? lastError,
    ConnectionHealthState? lastHealth,
    bool clearConnection = false,
    bool clearError = false,
  }) {
    return MobileConnectionState(
      status: status ?? this.status,
      activeConnection:
          clearConnection ? null : activeConnection ?? this.activeConnection,
      currentDevice: clearConnection ? null : currentDevice ?? this.currentDevice,
      lastError: clearError ? null : lastError ?? this.lastError,
      lastHealth: lastHealth ?? this.lastHealth,
    );
  }
}

class CameraCaptureState {
  const CameraCaptureState({
    required this.initialized,
    required this.capturing,
    this.lastCapturedPath,
    this.lastError,
  });

  factory CameraCaptureState.initial() => const CameraCaptureState(
        initialized: false,
        capturing: false,
      );

  final bool initialized;
  final bool capturing;
  final String? lastCapturedPath;
  final String? lastError;

  CameraCaptureState copyWith({
    bool? initialized,
    bool? capturing,
    String? lastCapturedPath,
    String? lastError,
    bool clearError = false,
  }) {
    return CameraCaptureState(
      initialized: initialized ?? this.initialized,
      capturing: capturing ?? this.capturing,
      lastCapturedPath: lastCapturedPath ?? this.lastCapturedPath,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

