import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

import 'package:windows_app/core/providers/app_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listenerState = ref.watch(desktopListenerStateProvider);
    final gallery = ref.watch(galleryDataProvider);

    return listenerState.when(
      data: (state) {
        return SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: SectionCard(
                      title: 'Connection',
                      subtitle: state.currentDevice == null
                          ? 'Waiting for a mobile device to pair.'
                          : 'Currently linked to ${state.currentDevice!.nickname}.',
                      actions: <Widget>[
                        FilledButton.tonal(
                          onPressed: () => context.go('/pairing'),
                          child: const Text('Pairing'),
                        ),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              StatusBadge(label: state.status.name),
                              if (state.activeConnection != null)
                                StatusBadge(
                                  label: state.activeConnection!.healthState.name,
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            state.lastError ??
                                'Listener healthy. Ready for pairing or trusted reconnect.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SectionCard(
                      title: 'Current Device',
                      subtitle: 'Trusted device and quick actions.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(state.currentDevice?.nickname ?? 'No connected device'),
                          const SizedBox(height: 12),
                          if (state.currentDevice != null)
                            Text('Last host: ${state.currentDevice!.lastKnownHost}'),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            children: <Widget>[
                              OutlinedButton(
                                onPressed: () => ref
                                    .read(pairingControllerProvider)
                                    .disconnectCurrent(),
                                child: const Text('Disconnect'),
                              ),
                              FilledButton.tonal(
                                onPressed: () => context.go('/trusted-devices'),
                                child: const Text('Manage Trust'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionCard(
                title: 'Latest Received Photos',
                subtitle: 'Live receive activity from the current save folder.',
                child: gallery.when(
                  data: (items) => items.isEmpty
                      ? const Text('No photos received yet.')
                      : SizedBox(
                          height: 260,
                          child: GridView.builder(
                            itemCount: items.take(6).length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final item = items[index];
                              final file = item.storagePath == null
                                  ? null
                                  : File(item.storagePath!);
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: <Widget>[
                                      if (file != null && file.existsSync())
                                        Image.file(file, fit: BoxFit.cover)
                                      else
                                        const Icon(Icons.photo, size: 42),
                                      Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          color: Colors.black54,
                                          child: Text(
                                            item.finalFilename,
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  error: (Object error, StackTrace stackTrace) => Text('$error'),
                  loading: () => const LinearProgressIndicator(),
                ),
              ),
            ],
          ),
        );
      },
      error: (Object error, StackTrace stackTrace) => Text('$error'),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

