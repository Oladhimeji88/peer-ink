import 'package:core_protocol/core_protocol.dart';
import 'package:test/test.dart';
import 'package:transfer_engine/transfer_engine.dart';

void main() {
  group('TransferQueueController', () {
    test('enqueues and retries a job', () async {
      final dispatched = <String>[];
      final controller = TransferQueueController(
        onDispatch: (TransferJob job) async {
          dispatched.add(job.jobId);
        },
      );
      final job = TransferJob(
        jobId: 'job-1',
        photo: PhotoMetadata(
          sourceFilePath: '/tmp/photo.jpg',
          originalFilename: 'photo.jpg',
          sanitizedFilename: 'photo.jpg',
          byteLength: 42,
          checksumSha256: 'abc123',
          capturedAt: DateTime.now().toUtc(),
          mimeType: 'image/jpeg',
          sourceDeviceId: 'mobile',
        ),
        status: TransferStatus.queued,
        createdAt: DateTime.now().toUtc(),
        attemptCount: 0,
        autoSend: true,
      );

      await controller.enqueue(job);
      await controller.retry(job.jobId);

      expect(dispatched, containsAll(<String>['job-1']));
    });
  });
}
