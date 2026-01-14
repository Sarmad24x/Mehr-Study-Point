import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/student_provider.dart';
import 'add_student_screen.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsStreamProvider);
    final filteredStudents = ref.watch(filteredStudentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) =>
                  ref.read(studentSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search by name, contact or seat...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: studentsAsync.when(
        data: (_) {
          if (filteredStudents.isEmpty) {
            return const Center(child: Text('No students found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(student.fullName[0].toUpperCase()),
                  ),
                  title: Text(student.fullName),
                  subtitle: Text('Seat: ${student.assignedSeatNumber ?? 'None'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Show student details
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudentScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
