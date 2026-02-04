
import 'package:flutter/material.dart';
import '../../../models/student_model.dart';
import '../student_details_screen.dart';

class StudentListItem extends StatelessWidget {
  final StudentModel student;

  const StudentListItem({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;

    switch (student.status) {
      case 'Active':
        statusColor = Colors.green;
        statusLabel = 'ACTIVE';
        break;
      case 'Archived':
        statusColor = Colors.red;
        statusLabel = 'EXPIRED';
        break;
      case 'Inactive':
        statusColor = Colors.orange;
        statusLabel = 'PENDING';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = student.status.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailsScreen(student: student),
            ),
          );
        },
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.orange.shade100,
              child: const Icon(Icons.person, color: Colors.orange, size: 30),
            ),
            const SizedBox(width: 16),
            // Name and Seat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      children: [
                        const TextSpan(text: 'Seat: '),
                        TextSpan(
                          text: student.assignedSeatNumber ?? 'N/A',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Status Chip and Chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
