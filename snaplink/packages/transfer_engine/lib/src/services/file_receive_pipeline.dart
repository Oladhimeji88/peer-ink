import 'dart:io';

import 'package:core_protocol/core_protocol.dart';
import 'package:path/path.dart' as p;

import 'package:transfer_engine/src/checksum/checksum_service.dart';
import 'package:transfer_engine/src/models/receive_pipeline_models.dart';

class FileReceivePipeline {
  FileReceivePipeline({
    ChecksumService? checksumService,
  }) : _checksumService = checksumService ?? const ChecksumService();

  final ChecksumService _checksumService;

  Future<ReceivePipelineResult> finalize(
    ReceivePipelineRequest request,
  ) async {
    final sanitized = sanitizeFilename(request.metadata.sanitizedFilename);
    final checksum = await _checksumService.hashFile(request.tempFile);
    if (checksum != request.metadata.checksumSha256) {
      throw const FileSystemException('Checksum mismatch.');
    }

    await request.targetDirectory.create(recursive: true);
    final targetPath = p.join(request.targetDirectory.path, sanitized);
    final targetFile = File(targetPath);
    final duplicate = await targetFile.exists() &&
        await _checksumService.hashFile(targetFile) == checksum;

    if (!duplicate) {
      await request.tempFile.rename(targetPath);
    } else if (await request.tempFile.exists()) {
      await request.tempFile.delete();
    }

    final result = TransferResult(
      jobId: request.transferJobId,
      status: TransferStatus.completed,
      completedAt: DateTime.now().toUtc(),
      finalFilename: sanitized,
      duplicate: duplicate,
      storagePath: targetPath,
      message: duplicate ? 'Duplicate ignored.' : 'Stored successfully.',
    );

    return ReceivePipelineResult(
      transferResult: result,
      finalFile: targetFile,
    );
  }
}

String sanitizeFilename(String input) {
  final invalidCharacters = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
  final normalized = input.replaceAll(invalidCharacters, '_').trim();
  return normalized.isEmpty ? 'snaplink_image.jpg' : normalized;
}

