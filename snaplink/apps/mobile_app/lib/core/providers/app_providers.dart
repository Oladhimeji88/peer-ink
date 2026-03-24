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
      late final TransferResult result;
      try {
        result = await connectionService.uploadJob(
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
      } catch (error) {
        result = TransferResult(
          jobId: job.jobId,
          status: TransferStatus.failed,
          completedAt: DateTime.now().toUtc(),
          finalFilename: job.photo.sanitizedFilename,
          duplicate: false,
          checksumSha256: job.photo.checksumSha256,
          storagePath: job.photo.sourceFilePath,
          message: error.toString(),
        );
      }
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
