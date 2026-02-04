import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _StatusFilterChip(label: 'All', value: null, currentFilter: currentFilter),
                const SizedBox(width: 10),
                _StatusFilterChip(label: 'Active', value: 'Active', currentFilter: currentFilter),
                const SizedBox(width: 10),
                _StatusFilterChip(label: 'Expired', value: 'Archived', currentFilter: currentFilter),
                const SizedBox(width: 10),
                _StatusFilterChip(label: 'Pending', value: 'Inactive', currentFilter: currentFilter),
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
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return _StudentListItem(student: student);
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

class _StatusFilterChip extends ConsumerWidget {
  final String label;
  final String? value;
  final String? currentFilter;

  const _StatusFilterChip({
    required this.label,
    required this.value,
    required this.currentFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = currentFilter == value;
    return GestureDetector(
      onTap: () {
        ref.read(studentStatusFilterProvider.notifier).state = value;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.shade700 
              : (Theme.of(context).brightness == Brightness.light ? Colors.grey[100] : Colors.grey[900]),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blueGrey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _StudentListItem extends StatelessWidget {
  final StudentModel student;

  const _StudentListItem({required this.student});

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
