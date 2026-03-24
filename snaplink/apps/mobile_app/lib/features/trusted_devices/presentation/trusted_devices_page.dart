import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../../core/providers/app_providers.dart';

class TrustedDevicesPage extends ConsumerWidget {
  const TrustedDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(trustedDevicesControllerProvider);
    final controller = ref.read(trustedDevicesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Trusted PCs')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SectionCard(
          title: 'Trusted PCs',
          subtitle: 'Forget a paired desktop and require a fresh QR scan.',
          child: devices.when(
            data: (items) => items.isEmpty
                ? const Text('No trusted PCs.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item.nickname),
                        subtitle:
                            Text('${item.lastKnownHost}:${item.lastKnownPort}'),
                        trailing: FilledButton.tonal(
                          onPressed: () => controller.forget(item.trustedDeviceId),
                          child: const Text('Forget'),
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
