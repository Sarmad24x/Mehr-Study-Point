import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/audit_provider.dart';

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
              final log = logs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  isThreeLine: true,
                  title: Text('${log.action} - ${log.entityType}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('By: ${log.userName}'),
                      Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(log.timestamp)}'),
                      if (log.action == 'UPDATE' && log.oldValues != null)
                        Text('Changes made to ID: ${log.entityId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  onTap: () {
                    _showLogDetails(context, log);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showLogDetails(BuildContext context, dynamic log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('User: ${log.userName}'),
              Text('Action: ${log.action}'),
              Text('Entity: ${log.entityType} (${log.entityId})'),
              const Divider(),
              if (log.oldValues != null) ...[
                const Text('Old Values:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.oldValues.toString()),
                const SizedBox(height: 8),
              ],
              if (log.newValues != null) ...[
                const Text('New Values:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.newValues.toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
