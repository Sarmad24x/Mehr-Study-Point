import 'package:flutter/material.dart';
import '../../../models/fee_model.dart';

class StatusChip extends StatelessWidget {
  final FeeStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case FeeStatus.paid:
        color = Colors.green;
        label = 'Paid';
        break;
      case FeeStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case FeeStatus.overdue:
        color = Colors.red;
        label = 'Overdue';
        break;
      case FeeStatus.partial:
        color = Colors.blue;
        label = 'Partial';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
