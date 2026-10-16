enum AppConnectionStatus {
  idle,
  waitingForScan,
  pairing,
  connected,
  receiving,
  error,
}

enum TransferStatus {
  queued,
  preprocessing,
  awaitingConnection,
  negotiating,
  uploading,
  ackPending,
  completed,
  duplicate,
  failed,
  canceled,
}

enum ConnectionHealthState {
  offline,
  degraded,
  good,
  excellent,
}

enum ProtocolMessageType {
  hello,
  pairRequest,
  pairResponse,
  authChallenge,
  authSuccess,
  heartbeat,
  heartbeatAck,
  uploadInit,
  uploadReady,
  uploadProgress,
  uploadComplete,
  uploadAck,
  uploadError,
  disconnect,
  revokeNotice,
}

enum ReceiveLogLevel {
  info,
  warning,
  error,
}

enum TrustedDevicePlatform {
  windows,
  android,
  ios,
  unknown,
}

