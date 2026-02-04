
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/student_provider.dart';
import 'add_student_screen.dart';
import 'widgets/student_list_item.dart';
import 'widgets/status_filter_chip.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsStreamProvider);
    final filteredStudents = ref.watch(filteredStudentsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[50]
          : null,
      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back button
        title: const Text('Student Management', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) =>
                  ref.read(studentSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search students or seat numbers...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueGrey, size: 24),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filters
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                StatusFilterChip(label: 'All', value: null),
                SizedBox(width: 10),
                StatusFilterChip(label: 'Active', value: 'Active'),
                SizedBox(width: 10),
                StatusFilterChip(label: 'Expired', value: 'Archived'),
                SizedBox(width: 10),
                StatusFilterChip(label: 'Pending', value: 'Inactive'),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 20, top: 16, bottom: 8),
            child: Text(
              'RECENT MEMBERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                letterSpacing: 1.1,
              ),
            ),
          ),

          Expanded(
            child: studentsAsync.when(
              data: (_) {
                if (filteredStudents.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filteredStudents.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return StudentListItem(student: student);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudentScreen()),
          );
        },
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
