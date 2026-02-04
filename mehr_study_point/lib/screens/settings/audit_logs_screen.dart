
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audit_provider.dart';
import 'widgets/audit_log_item.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No logs found.'));
          }
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return AuditLogItem(log: logs[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
