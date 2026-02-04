import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/fee_model.dart';
import '../../../models/student_model.dart';

class RenewalItem extends StatelessWidget {
  final FeeModel fee;
  final StudentModel student;

  const RenewalItem({
    super.key,
    required this.fee,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = fee.amount - fee.paidAmount;
    final now = DateTime.now();
    final isDueToday = fee.dueDate.day == now.day &&
        fee.dueDate.month == now.month &&
        fee.dueDate.year == now.year;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: theme.brightness == Brightness.dark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
            child: Text(
              student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Owed: Rs. ${remaining.toInt()}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            isDueToday ? 'Due Today' : 'Due: ${DateFormat('dd MMM').format(fee.dueDate)}',
            style: theme.textTheme.bodySmall?.copyWith(
                color: isDueToday ? theme.colorScheme.error : null,
                fontWeight: isDueToday ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
