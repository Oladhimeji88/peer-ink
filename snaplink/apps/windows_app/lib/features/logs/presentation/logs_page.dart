import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../../core/providers/app_providers.dart';

class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsProvider);

    return SectionCard(
      title: 'Transfer Logs',
      subtitle: 'Searchable audit trail for pairing, transfer, and reconnect events.',
      child: logs.when(
        data: (items) => items.isEmpty
            ? const Text('No logs yet.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final entry = items[index];
                  return ListTile(
                    dense: true,
                    title: Text(entry.message),
                    subtitle: Text(entry.timestamp.toLocal().toString()),
                    trailing: StatusBadge(label: entry.level.name),
                  );
                },
              ),
        error: (Object error, StackTrace stackTrace) => Text('$error'),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

