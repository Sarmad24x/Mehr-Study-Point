import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_student_screen.dart';
import 'student_list_controller.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No students found.'));
          }
          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                title: Text(student.fullName),
                subtitle: Text(student.contactNumber),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddStudentScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
