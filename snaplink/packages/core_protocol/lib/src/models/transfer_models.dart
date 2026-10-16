import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core_protocol/src/enums/protocol_enums.dart';

part 'transfer_models.freezed.dart';
part 'transfer_models.g.dart';

@freezed
class PhotoMetadata with _$PhotoMetadata {
  const factory PhotoMetadata({
    required String sourceFilePath,
    required String originalFilename,
    required String sanitizedFilename,
    required int byteLength,
    required String checksumSha256,
    required DateTime capturedAt,
    required String mimeType,
    required String sourceDeviceId,
    int? width,
    int? height,
    int? compressionQuality,
  }) = _PhotoMetadata;

  factory PhotoMetadata.fromJson(Map<String, dynamic> json) =>
      _$PhotoMetadataFromJson(json);
}

@freezed
class TransferJob with _$TransferJob {
  const factory TransferJob({
    required String jobId,
    required PhotoMetadata photo,
    required TransferStatus status,
    required DateTime createdAt,
    required int attemptCount,
    required bool autoSend,
    String? trustedDeviceId,
    String? uploadId,
    String? errorMessage,
  }) = _TransferJob;

  factory TransferJob.fromJson(Map<String, dynamic> json) =>
      _$TransferJobFromJson(json);
}

@freezed
class TransferProgress with _$TransferProgress {
  const factory TransferProgress({
    required String jobId,
    required int bytesSent,
    required int totalBytes,
    required double percent,
    required TransferStatus status,
  }) = _TransferProgress;

  factory TransferProgress.fromJson(Map<String, dynamic> json) =>
      _$TransferProgressFromJson(json);
}

@freezed
class TransferResult with _$TransferResult {
  const factory TransferResult({
    required String jobId,
    required TransferStatus status,
    required DateTime completedAt,
    required String finalFilename,
    required bool duplicate,
    String? checksumSha256,
    String? storagePath,
    String? message,
  }) = _TransferResult;

  factory TransferResult.fromJson(Map<String, dynamic> json) =>
      _$TransferResultFromJson(json);
}
