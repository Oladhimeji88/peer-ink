import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../../core/providers/app_providers.dart';

class ConnectPage extends ConsumerWidget {
  const ConnectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(mobileConnectionStateProvider);
    final trustedDevices = ref.watch(trustedDevicesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to PC'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: <Widget>[
            connectionState.when(
              data: (state) => SectionCard(
                title: 'Connection Status',
                subtitle: state.currentDevice == null
                    ? 'No desktop connected.'
                    : 'Connected to ${state.currentDevice!.nickname}.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 12,
                      children: <Widget>[
                        StatusBadge(label: state.status.name),
                        StatusBadge(label: state.lastHealth.name),
                      ],
                    ),
                    if (state.lastError != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(state.lastError!),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      children: <Widget>[
                        FilledButton(
                          onPressed: () => context.go('/scan'),
                          child: const Text('Connect via QR'),
                        ),
                        OutlinedButton(
                          onPressed: state.currentDevice == null
                              ? null
                              : () => context.go('/camera'),
                          child: const Text('Open Camera'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              error: (Object error, StackTrace stackTrace) => Text('$error'),
              loading: () => const LinearProgressIndicator(),
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: 'Trusted PCs',
              subtitle: 'Reconnect without scanning when the listener is available.',
              actions: <Widget>[
                IconButton(
                  onPressed: () => context.go('/trusted-devices'),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
              child: trustedDevices.when(
                data: (items) => items.isEmpty
                    ? const Text('No trusted PCs yet.')
                    : Column(
                        children: items
                            .map(
                              (item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.nickname),
                                subtitle: Text(
                                  '${item.lastKnownHost}:${item.lastKnownPort}',
                                ),
                                trailing: FilledButton.tonal(
                                  onPressed: () => ref
                                      .read(mobileConnectionServiceProvider)
                                      .reconnect(item),
                                  child: const Text('Reconnect'),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                error: (Object error, StackTrace stackTrace) => Text('$error'),
                loading: () => const LinearProgressIndicator(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: () => context.go('/history'),
              child: const Text('Recent Transfers'),
            ),
          ],
        ),
      ),
    );
  }
}

