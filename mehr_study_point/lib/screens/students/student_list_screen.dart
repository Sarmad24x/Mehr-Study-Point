import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/student_provider.dart';
import 'add_student_screen.dart';
import 'student_details_screen.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsStreamProvider);
    final filteredStudents = ref.watch(filteredStudentsProvider);
    final currentFilter = ref.watch(studentStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  onChanged: (value) =>
                      ref.read(studentSearchQueryProvider.notifier).state = value,
                  decoration: InputDecoration(
                    hintText: 'Search by name, contact or seat...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _filterChip(ref, 'Active', currentFilter),
                    const SizedBox(width: 8),
                    _filterChip(ref, 'Archived', currentFilter),
                    const SizedBox(width: 8),
                    _filterChip(ref, null, currentFilter, label: 'All'),
                  ],
                ),
              ),
            ],
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
              final isArchived = student.status == 'Archived';

              return Card(
                color: isArchived ? Colors.grey.shade100 : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isArchived ? Colors.grey : null,
                    child: Text(
                      student.fullName[0].toUpperCase(),
                      style: TextStyle(color: isArchived ? Colors.white : null),
                    ),
                  ),
                  title: Text(
                    student.fullName,
                    style: TextStyle(
                      decoration: isArchived ? TextDecoration.lineThrough : null,
                      color: isArchived ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(isArchived 
                    ? 'Status: Left' 
                    : 'Seat: ${student.assignedSeatNumber ?? 'None'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentDetailsScreen(student: student),
                      ),
                    );
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

  Widget _filterChip(WidgetRef ref, String? status, String? currentFilter, {String? label}) {
    final isSelected = currentFilter == status;
    return FilterChip(
      label: Text(label ?? status!),
      selected: isSelected,
      onSelected: (val) {
        ref.read(studentStatusFilterProvider.notifier).state = status;
      },
    );
  }
}
