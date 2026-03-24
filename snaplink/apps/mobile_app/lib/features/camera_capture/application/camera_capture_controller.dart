import 'dart:io';

import 'package:core_protocol/core_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transfer_engine/transfer_engine.dart';

import '../../../core/models/mobile_connection_state.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/camera_capture_service.dart';

class CameraCaptureController extends StateNotifier<CameraCaptureState> {
  CameraCaptureController({
    required CameraCaptureService cameraService,
    required TransferQueueController queueController,
    required ISettingsRepository settingsRepository,
  })  : _cameraService = cameraService,
        _queueController = queueController,
        _settingsRepository = settingsRepository,
        _checksumService = const ChecksumService(),
        super(CameraCaptureState.initial());

  final CameraCaptureService _cameraService;
  final TransferQueueController _queueController;
  final ISettingsRepository _settingsRepository;
  final ChecksumService _checksumService;

  CameraCaptureService get service => _cameraService;

  Future<void> initialize() async {
    final ready = await _cameraService.initialize();
    state = state.copyWith(
      initialized: ready,
      lastError: ready ? null : 'Camera permission or hardware unavailable.',
    );
  }

  Future<void> capture({bool? autoSend}) async {
    state = state.copyWith(capturing: true, clearError: true);
    try {
      final shot = await _cameraService.capture();
      final file = File(shot.path);
      final settings = await _settingsRepository.read();
      final checksum = await _checksumService.hashFile(file);
      final job = buildTransferJobFromFile(
        path: shot.path,
        checksum: checksum,
        length: await file.length(),
      ).copyWith(autoSend: autoSend ?? !settings.reviewBeforeSend);
      if (job.autoSend) {
        await _queueController.enqueue(job);
      }
      state = state.copyWith(
        capturing: false,
        lastCapturedPath: shot.path,
      );
    } catch (error) {
      state = state.copyWith(capturing: false, lastError: error.toString());
    }
  }
}

