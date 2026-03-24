import 'dart:async';

import 'package:collection/collection.dart';
import 'package:core_protocol/core_protocol.dart';

class TransferQueueController implements ITransferEngine {
  TransferQueueController({
    required Future<void> Function(TransferJob job) onDispatch,
  }) : _onDispatch = onDispatch;

  final Future<void> Function(TransferJob job) _onDispatch;
  final List<TransferJob> _jobs = <TransferJob>[];
  final StreamController<List<TransferJob>> _queueController =
      StreamController<List<TransferJob>>.broadcast();
  final StreamController<TransferProgress> _progressController =
      StreamController<TransferProgress>.broadcast();

  @override
  Future<void> cancel(String jobId) async {
    final index = _jobs.indexWhere((job) => job.jobId == jobId);
    if (index == -1) {
      return;
    }
    _jobs[index] = _jobs[index].copyWith(status: TransferStatus.canceled);
    _emitQueue();
  }

  @override
  Future<void> enqueue(TransferJob job) async {
    _jobs.add(job);
    _emitQueue();
    await _dispatch(job.copyWith(status: TransferStatus.queued));
  }

  @override
  Future<void> retry(String jobId) async {
    final job = _jobs.firstWhereOrNull((item) => item.jobId == jobId);
    if (job == null) {
      return;
    }
    final updated = job.copyWith(
      status: TransferStatus.awaitingConnection,
      attemptCount: job.attemptCount + 1,
      errorMessage: null,
    );
    _replace(updated);
    await _dispatch(updated);
  }

  Future<void> markProgress(TransferProgress progress) async {
    _progressController.add(progress);
    final job = _jobs.firstWhereOrNull((item) => item.jobId == progress.jobId);
    if (job == null) {
      return;
    }
    _replace(job.copyWith(status: progress.status));
  }

  Future<void> markResult(TransferResult result) async {
    final job = _jobs.firstWhereOrNull((item) => item.jobId == result.jobId);
    if (job == null) {
      return;
    }
    final status =
        result.duplicate ? TransferStatus.duplicate : result.status;
    _replace(job.copyWith(status: status, errorMessage: result.message));
  }

  @override
  Stream<TransferProgress> watchProgress() => _progressController.stream;

  @override
  Stream<List<TransferJob>> watchQueue() => _queueController.stream;

  Future<void> dispose() async {
    await _queueController.close();
    await _progressController.close();
  }

  Future<void> _dispatch(TransferJob job) async {
    _replace(job.copyWith(status: TransferStatus.negotiating));
    await _onDispatch(job);
  }

  void _emitQueue() {
    _queueController.add(List<TransferJob>.unmodifiable(_jobs));
  }

  void _replace(TransferJob updated) {
    final index = _jobs.indexWhere((job) => job.jobId == updated.jobId);
    if (index == -1) {
      return;
    }
    _jobs[index] = updated;
    _emitQueue();
  }
}
