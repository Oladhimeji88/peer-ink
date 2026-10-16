import 'package:freezed_annotation/freezed_annotation.dart';

part 'protocol_models.freezed.dart';
part 'protocol_models.g.dart';

@freezed
class ProtocolMessage with _$ProtocolMessage {
  const factory ProtocolMessage({
    required String messageId,
    required String type,
    required int protocolVersion,
    required DateTime timestamp,
    required Map<String, dynamic> payload,
  }) = _ProtocolMessage;

  factory ProtocolMessage.fromJson(Map<String, dynamic> json) =>
      _$ProtocolMessageFromJson(json);
}

@freezed
class PairingRequest with _$PairingRequest {
  const factory PairingRequest({
    required String sessionId,
    required String oneTimePairingToken,
    required String mobileDeviceId,
    required String mobileDeviceName,
    required String clientNonce,
    required DateTime requestedAt,
    required String certificateFingerprint,
    required Map<String, bool> capabilities,
  }) = _PairingRequest;

  factory PairingRequest.fromJson(Map<String, dynamic> json) =>
      _$PairingRequestFromJson(json);
}

@freezed
class PairingResponse with _$PairingResponse {
  const factory PairingResponse({
    required bool accepted,
    required String desktopDeviceId,
    required String trustedDeviceId,
    required String refreshSecret,
    required DateTime issuedAt,
    required DateTime expiresAt,
    String? rejectionReason,
  }) = _PairingResponse;

  factory PairingResponse.fromJson(Map<String, dynamic> json) =>
      _$PairingResponseFromJson(json);
}

@freezed
class UploadInitRequest with _$UploadInitRequest {
  const factory UploadInitRequest({
    required String transferJobId,
    required String sanitizedFilename,
    required int byteLength,
    required String checksumSha256,
    required DateTime capturedAt,
    required String mimeType,
    required String sourceDeviceId,
    required int compressionQuality,
  }) = _UploadInitRequest;

  factory UploadInitRequest.fromJson(Map<String, dynamic> json) =>
      _$UploadInitRequestFromJson(json);
}

@freezed
class UploadInitResponse with _$UploadInitResponse {
  const factory UploadInitResponse({
    required bool accepted,
    required String uploadId,
    required Uri uploadUrl,
    required int maxAcceptedBytes,
    String? rejectionReason,
  }) = _UploadInitResponse;

  factory UploadInitResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadInitResponseFromJson(json);
}

@freezed
class UploadAck with _$UploadAck {
  const factory UploadAck({
    required String transferJobId,
    required String uploadId,
    required bool success,
    required bool duplicate,
    required String finalFilename,
    required DateTime completedAt,
    String? message,
  }) = _UploadAck;

  factory UploadAck.fromJson(Map<String, dynamic> json) =>
      _$UploadAckFromJson(json);
}

@freezed
class ErrorMessage with _$ErrorMessage {
  const factory ErrorMessage({
    required String code,
    required String message,
    Map<String, dynamic>? details,
  }) = _ErrorMessage;

  factory ErrorMessage.fromJson(Map<String, dynamic> json) =>
      _$ErrorMessageFromJson(json);
}

