import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../../core/providers/app_providers.dart';

class GalleryPage extends ConsumerWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryDataProvider);

    return SectionCard(
      title: 'Gallery',
      subtitle: 'Received images, metadata, and duplicate handling state.',
      child: gallery.when(
        data: (items) => items.isEmpty
            ? const Text('No photos received yet.')
            : GridView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final item = items[index];
                  final file =
                      item.storagePath == null ? null : File(item.storagePath!);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: file != null && file.existsSync()
                                  ? Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Center(child: Icon(Icons.photo)),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.finalFilename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('Completed: ${item.completedAt.toLocal()}'),
                          if (item.checksumSha256 != null)
                            Text(
                              'Checksum: ${item.checksumSha256!.substring(0, 12)}...',
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        error: (Object error, StackTrace stackTrace) => Text('$error'),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
