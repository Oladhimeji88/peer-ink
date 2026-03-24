import 'package:core_protocol/core_protocol.dart';

class DesktopListenerState {
  const DesktopListenerState({
    required this.status,
    required this.serverRunning,
    this.pairingSession,
    this.qrPayload,
    this.activeConnection,
    this.currentDevice,
    this.lastError,
  });

  factory DesktopListenerState.initial() => const DesktopListenerState(
        status: AppConnectionStatus.idle,
        serverRunning: false,
      );

  final AppConnectionStatus status;
  final bool serverRunning;
  final PairingSession? pairingSession;
  final String? qrPayload;
  final ActiveConnection? activeConnection;
  final TrustedDevice? currentDevice;
  final String? lastError;

  DesktopListenerState copyWith({
    AppConnectionStatus? status,
    bool? serverRunning,
    PairingSession? pairingSession,
    String? qrPayload,
    ActiveConnection? activeConnection,
    TrustedDevice? currentDevice,
    String? lastError,
    bool clearPairing = false,
    bool clearError = false,
    bool clearConnection = false,
  }) {
    return DesktopListenerState(
      status: status ?? this.status,
      serverRunning: serverRunning ?? this.serverRunning,
      pairingSession: clearPairing ? null : pairingSession ?? this.pairingSession,
      qrPayload: clearPairing ? null : qrPayload ?? this.qrPayload,
      activeConnection:
          clearConnection ? null : activeConnection ?? this.activeConnection,
      currentDevice: clearConnection ? null : currentDevice ?? this.currentDevice,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

