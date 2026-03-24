import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../../core/providers/app_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: settingsState.when(
          data: (settings) => SectionCard(
            title: 'Capture & Transfer',
            subtitle: 'Tune how images are prepared and sent.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('JPEG Quality: ${settings.compressionQuality}'),
                Slider(
                  value: settings.compressionQuality.toDouble(),
                  min: 50,
                  max: 100,
                  divisions: 10,
                  label: settings.compressionQuality.toString(),
                  onChanged: (double value) => controller.save(
                    settings.copyWith(compressionQuality: value.round()),
                  ),
                ),
                SwitchListTile.adaptive(
                  value: settings.reviewBeforeSend,
                  onChanged: (bool value) =>
                      controller.save(settings.copyWith(reviewBeforeSend: value)),
                  title: const Text('Review before send'),
                ),
                SwitchListTile.adaptive(
                  value: settings.rememberTrustedDevices,
                  onChanged: (bool value) => controller.save(
                    settings.copyWith(rememberTrustedDevices: value),
                  ),
                  title: const Text('Remember trusted desktops'),
                ),
              ],
            ),
          ),
          error: (Object error, StackTrace stackTrace) => Text('$error'),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

