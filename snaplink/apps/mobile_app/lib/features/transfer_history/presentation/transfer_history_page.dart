import 'dart:io';

import 'package:core_protocol/core_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

import 'package:mobile_app/core/providers/app_providers.dart';

class TransferHistoryPage extends ConsumerWidget {
  const TransferHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(transferHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go('/connect'),
            icon: const Icon(Icons.link),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SectionCard(
          title: 'Recent Transfers',
          subtitle: 'Sent photos, completion state, and duplicate acknowledgements.',
          child: history.when(
            data: (items) => items.isEmpty
                ? const Text('No transfers yet.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item.finalFilename),
                        subtitle: Text(item.completedAt.toLocal().toString()),
                        trailing: Wrap(
                          spacing: 12,
                          children: <Widget>[
                            StatusBadge(
                              label: item.duplicate ? 'duplicate' : item.status.name,
                            ),
                            if (item.storagePath != null)
                              FilledButton.tonal(
                                onPressed: () async {
                                  final file = File(item.storagePath!);
                                  if (!file.existsSync()) {
                                    return;
                                  }
                                  await ref.read(transferQueueProvider).enqueue(
                                        TransferJob(
                                          jobId: '${item.jobId}_retry',
                                          photo: PhotoMetadata(
                                            sourceFilePath: item.storagePath!,
                                            originalFilename: item.finalFilename,
                                            sanitizedFilename: item.finalFilename,
                                            byteLength: await file.length(),
                                            checksumSha256:
                                                item.checksumSha256 ?? '',
                                            capturedAt: DateTime.now().toUtc(),
                                            mimeType: 'image/jpeg',
                                            sourceDeviceId: 'mobile',
                                          ),
                                          status: TransferStatus.queued,
                                          createdAt: DateTime.now().toUtc(),
                                          attemptCount: 0,
                                          autoSend: true,
                                        ),
                                      );
                                },
                                child: const Text('Resend'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
            error: (Object error, StackTrace stackTrace) => Text('$error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}
