import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_providers.dart';
import '../domain/student.dart';
import 'edit_student_screen.dart';
import 'student_list_controller.dart';

final studentDetailProvider = FutureProvider.autoDispose.family<Student, String>((ref, studentId) {
  final studentRepository = ref.watch(studentRepositoryProvider);
  return studentRepository.getStudent(studentId);
});

class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  Future<void> _deleteStudent(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this student? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(studentRepositoryProvider).deleteStudent(studentId);
        ref.invalidate(studentListControllerProvider);
        Navigator.of(context).pop(); // Go back to the list screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete student: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        actions: [
          studentAsync.when(
            data: (student) => Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditStudentScreen(student: student),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteStudent(context, ref),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: studentAsync.when(
        data: (student) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(studentDetailProvider(studentId).future),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Full Name', student.fullName),
                  _buildDetailRow('Contact Number', student.contactNumber),
                  _buildDetailRow('Address', student.address),
                  if (student.guardianName != null && student.guardianName!.isNotEmpty)
                    _buildDetailRow('Guardian Name', student.guardianName!),
                  if (student.guardianContactNumber != null && student.guardianContactNumber!.isNotEmpty)
                    _buildDetailRow('Guardian Contact', student.guardianContactNumber!),
                  _buildDetailRow('Admission Date', student.admissionDate.toLocal().toString().split(' ')[0]),
                  _buildDetailRow('Status', student.isActive ? 'Active' : 'Inactive'),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
          const Divider(),
        ],
      ),
    );
  }
}
