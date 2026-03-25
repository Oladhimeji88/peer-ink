import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import 'package:windows_app/core/providers/app_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _saveDirectoryController;

  @override
  void initState() {
    super.initState();
    _saveDirectoryController = TextEditingController();
  }

  @override
  void dispose() {
    _saveDirectoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return settingsState.when(
      data: (settings) {
        _saveDirectoryController.text = settings.saveDirectory;
        return SectionCard(
          title: 'Settings',
          subtitle: 'Storage, notifications, and listener preferences.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _saveDirectoryController,
                decoration: const InputDecoration(
                  labelText: 'Save Folder',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: <Widget>[
                  FilterChip(
                    label: const Text('Auto-accept trusted devices'),
                    selected: settings.autoAcceptTrustedDevices,
                    onSelected: (bool value) => controller.save(
                      settings.copyWith(autoAcceptTrustedDevices: value),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Receive notifications'),
                    selected: settings.notificationsEnabled,
                    onSelected: (bool value) => controller.save(
                      settings.copyWith(notificationsEnabled: value),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Receive sound'),
                    selected: settings.receiveSoundEnabled,
                    onSelected: (bool value) => controller.save(
                      settings.copyWith(receiveSoundEnabled: value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                children: <Widget>[
                  FilledButton(
                    onPressed: () => controller.save(
                      settings.copyWith(
                        saveDirectory: _saveDirectoryController.text.trim(),
                      ),
                    ),
                    child: const Text('Save Settings'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      if (settings.saveDirectory.isNotEmpty) {
                        Process.run('explorer', <String>[settings.saveDirectory]);
                      }
                    },
                    child: const Text('Open Save Folder'),
                  ),
                ],
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

