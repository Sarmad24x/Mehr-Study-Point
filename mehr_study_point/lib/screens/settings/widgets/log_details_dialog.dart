
import 'package:flutter/material.dart';

class LogDetailsDialog extends StatelessWidget {
  final dynamic log;

  const LogDetailsDialog({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
    );
  }
}
