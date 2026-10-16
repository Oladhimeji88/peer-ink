import 'dart:io';

import 'package:core_protocol/core_protocol.dart';

class ReceivePipelineRequest {
  const ReceivePipelineRequest({
    required this.transferJobId,
    required this.device,
    required this.metadata,
    required this.tempFile,
    required this.targetDirectory,
  });

  final String transferJobId;
  final TrustedDevice device;
  final PhotoMetadata metadata;
  final File tempFile;
  final Directory targetDirectory;
}

class ReceivePipelineResult {
  const ReceivePipelineResult({
    required this.transferResult,
    required this.finalFile,
  });

  final TransferResult transferResult;
  final File finalFile;
}

