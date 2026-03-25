import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import 'package:windows_app/core/providers/app_providers.dart';

class TrustedDevicesPage extends ConsumerWidget {
  const TrustedDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesState = ref.watch(trustedDevicesControllerProvider);
    final controller = ref.read(trustedDevicesControllerProvider.notifier);

    return SectionCard(
      title: 'Trusted Devices',
      subtitle: 'Revoke, rename, and inspect remembered mobile devices.',
      child: devicesState.when(
        data: (devices) => devices.isEmpty
            ? const Text('No trusted devices.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: devices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final device = devices[index];
                  return ListTile(
                    title: Text(device.nickname),
                    subtitle: Text(
                      '${device.lastKnownHost}:${device.lastKnownPort} • last seen ${device.lastConnectedAt.toLocal()}',
                    ),
                    trailing: Wrap(
                      spacing: 12,
                      children: <Widget>[
                        StatusBadge(label: device.revoked ? 'revoked' : 'trusted'),
                        FilledButton.tonal(
                          onPressed: () async {
                            final textController = TextEditingController(
                              text: device.nickname,
                            );
                            await showDialog<void>(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: const Text('Edit Nickname'),
                                  content: TextField(controller: textController),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                        await controller.rename(
                                          device,
                                          textController.text.trim().isEmpty
                                              ? device.deviceName
                                              : textController.text.trim(),
                                        );
                                        if (dialogContext.mounted) {
                                          Navigator.of(dialogContext).pop();
                                        }
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text('Rename'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => controller.revoke(device.trustedDeviceId),
                          child: const Text('Revoke'),
                        ),
                      ],
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
