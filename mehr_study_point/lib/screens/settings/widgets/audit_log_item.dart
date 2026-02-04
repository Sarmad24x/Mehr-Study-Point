
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'log_details_dialog.dart';

class AuditLogItem extends StatelessWidget {
  final dynamic log;

  const AuditLogItem({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
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
              Text('Changes made to ID: ${log.entityId}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => LogDetailsDialog(log: log),
          );
        },
      ),
    );
  }
}
