import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../../core/providers/app_providers.dart';

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
                        trailing: StatusBadge(
                          label: item.duplicate ? 'duplicate' : item.status.name,
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

