import 'dart:io';

import 'package:core_protocol/core_protocol.dart';
import 'package:device_security/device_security.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transfer_engine/transfer_engine.dart';

import '../../features/camera_capture/application/camera_capture_controller.dart';
import '../../features/settings/application/settings_controller.dart';
import '../../features/trusted_devices/application/trusted_devices_controller.dart';
import '../models/mobile_connection_state.dart';
import '../services/camera_capture_service.dart';
import '../services/mobile_connection_service.dart';
import '../services/support_services.dart';

final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  throw UnimplementedError();
});

final transferHistoryRepositoryProvider = Provider<ITransferHistoryRepository>((ref) {
  throw UnimplementedError();
});

final trustRegistryProvider = Provider<ITrustRegistry>((ref) {
  throw UnimplementedError();
});

final telemetrySinkProvider = Provider<ITelemetrySink>((ref) {
  throw UnimplementedError();
});

final trustedSecretVaultProvider = Provider<TrustedSecretVault>((ref) {
  throw UnimplementedError();
});

final mobileConnectionServiceProvider = Provider<MobileConnectionService>((ref) {
  throw UnimplementedError();
});

final cameraCaptureServiceProvider = Provider<CameraCaptureService>((ref) {
  throw UnimplementedError();
});

final mobileConnectionStateProvider =
    StreamProvider<MobileConnectionState>((ref) {
  return ref.watch(mobileConnectionServiceProvider).watchState();
});

final transferHistoryProvider = StreamProvider<List<TransferResult>>((ref) {
  return ref.watch(transferHistoryRepositoryProvider).watchHistory();
});

final trustedDevicesControllerProvider = StateNotifierProvider<
    TrustedDevicesController, AsyncValue<List<TrustedDevice>>>((ref) {
  return TrustedDevicesController(ref.watch(trustRegistryProvider));
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<AppSettings>>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider));
});

final transferQueueProvider = Provider<TransferQueueController>((ref) {
  final connectionService = ref.watch(mobileConnectionServiceProvider);
  final historyRepository = ref.watch(transferHistoryRepositoryProvider);
  late final TransferQueueController queue;
  queue = TransferQueueController(
    onDispatch: (TransferJob job) async {
      final result = await connectionService.uploadJob(
        job,
        onProgress: (int sent, int total) {
          queue.markProgress(
            TransferProgress(
              jobId: job.jobId,
              bytesSent: sent,
              totalBytes: total,
              percent: total == 0 ? 0 : sent / total,
              status: TransferStatus.uploading,
            ),
          );
        },
      );
      await historyRepository.add(result);
      await queue.markResult(result);
    },
  );
  ref.onDispose(() {
    queue.dispose();
  });
  return queue;
});

final transferQueueStateProvider = StreamProvider<List<TransferJob>>((ref) {
  return ref.watch(transferQueueProvider).watchQueue();
});

final cameraCaptureControllerProvider = StateNotifierProvider<
    CameraCaptureController, CameraCaptureState>((ref) {
  return CameraCaptureController(
    cameraService: ref.watch(cameraCaptureServiceProvider),
    queueController: ref.watch(transferQueueProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

TransferJob buildTransferJobFromFile({
  required String path,
  required String checksum,
  required int length,
}) {
  final file = File(path);
  final filename = file.uri.pathSegments.isEmpty
      ? 'snaplink_image.jpg'
      : file.uri.pathSegments.last;
  return TransferJob(
    jobId: DateTime.now().microsecondsSinceEpoch.toString(),
    photo: PhotoMetadata(
      sourceFilePath: path,
      originalFilename: filename,
      sanitizedFilename: filename,
      byteLength: length,
      checksumSha256: checksum,
      capturedAt: DateTime.now().toUtc(),
      mimeType: 'image/jpeg',
      sourceDeviceId: 'mobile',
      compressionQuality: 88,
    ),
    status: TransferStatus.queued,
    createdAt: DateTime.now().toUtc(),
    attemptCount: 0,
    autoSend: true,
  );
}
