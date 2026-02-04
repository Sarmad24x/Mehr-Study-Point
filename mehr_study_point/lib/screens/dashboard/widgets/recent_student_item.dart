
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/student_model.dart';

class RecentStudentItem extends StatelessWidget {
  final StudentModel student;

  const RecentStudentItem({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(
              student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.primary,
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
                  'Seat: ${student.assignedSeatNumber ?? 'N/A'}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            DateFormat('dd MMM').format(student.admissionDate),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
