import 'dart:io';

import 'package:core_protocol/core_protocol.dart';
import 'package:test/test.dart';
import 'package:transfer_engine/transfer_engine.dart';

void main() {
  group('FileReceivePipeline', () {
    test('stores a file and returns a success result', () async {
      final tempRoot = await Directory.systemTemp.createTemp('snaplink_pipeline');
      final incomingFile = File('${tempRoot.path}/incoming.part')
        ..writeAsStringSync('photo-bytes');
      final checksum = const ChecksumService().hashString('photo-bytes');
      final pipeline = FileReceivePipeline();

      final result = await pipeline.finalize(
        ReceivePipelineRequest(
          transferJobId: 'job-1',
          device: TrustedDevice(
            trustedDeviceId: 'trusted-1',
            desktopDeviceId: 'desktop-1',
            deviceName: 'Phone',
            nickname: 'Phone',
            platform: TrustedDevicePlatform.android,
            pairedAt: DateTime.now().toUtc(),
            lastConnectedAt: DateTime.now().toUtc(),
            lastKnownHost: '192.168.1.2',
            lastKnownPort: 42817,
            certificateSha256: 'abc123',
            revoked: false,
            autoReconnect: true,
          ),
          metadata: PhotoMetadata(
            sourceFilePath: incomingFile.path,
            originalFilename: 'photo.jpg',
            sanitizedFilename: 'photo.jpg',
            byteLength: incomingFile.lengthSync(),
            checksumSha256: checksum,
            capturedAt: DateTime.now().toUtc(),
            mimeType: 'image/jpeg',
            sourceDeviceId: 'mobile',
          ),
          tempFile: incomingFile,
          targetDirectory: Directory('${tempRoot.path}/final'),
        ),
      );

      expect(result.transferResult.duplicate, isFalse);
      expect(File(result.transferResult.storagePath!).existsSync(), isTrue);
    });
  });
}

