
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import 'add_student_screen.dart';
import 'widgets/student_list_item.dart';
import 'widgets/status_filter_chip.dart';

// Provider to track selected student IDs
final selectedStudentIdsProvider = StateProvider<Set<String>>((ref) => {});
final isSelectionModeProvider = StateProvider<bool>((ref) => false);

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsStreamProvider);
    final filteredStudents = ref.watch(filteredStudentsProvider);
    final selectedIds = ref.watch(selectedStudentIdsProvider);
    final isSelectionMode = ref.watch(isSelectionModeProvider);
    final userProfile = ref.watch(userProfileProvider).value;

    return WillPopScope(
      onWillPop: () async {
        if (isSelectionMode) {
          ref.read(isSelectionModeProvider.notifier).state = false;
          ref.read(selectedStudentIdsProvider.notifier).state = {};
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[50]
            : null,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            isSelectionMode ? '${selectedIds.length} Selected' : 'Student Management',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isSelectionMode ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          leading: isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(isSelectionModeProvider.notifier).state = false;
                    ref.read(selectedStudentIdsProvider.notifier).state = {};
                  },
                )
              : null,
          actions: [
            if (isSelectionMode) ...[
              IconButton(
                icon: const Icon(Icons.archive_outlined, color: Colors.orange),
                tooltip: 'Archive Selected',
                onPressed: () => _handleBulkArchive(context, ref, selectedIds, userProfile),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Selected',
                onPressed: () => _handleBulkDelete(context, ref, selectedIds, userProfile),
              ),
            ] else
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (val) {
                  if (val == 'select') {
                    ref.read(isSelectionModeProvider.notifier).state = true;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'select',
                    child: ListTile(
                      leading: Icon(Icons.check_box_outlined),
                      title: Text('Select Multiple'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
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
                'STUDENT LIST',
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
                      final isSelected = selectedIds.contains(student.id);

                      return InkWell(
                        onLongPress: () {
                          if (!isSelectionMode) {
                            ref.read(isSelectionModeProvider.notifier).state = true;
                            ref.read(selectedStudentIdsProvider.notifier).state = {student.id};
                          }
                        },
                        onTap: () {
                          if (isSelectionMode) {
                            final newSelection = Set<String>.from(selectedIds);
                            if (isSelected) {
                              newSelection.remove(student.id);
                              if (newSelection.isEmpty) {
                                ref.read(isSelectionModeProvider.notifier).state = false;
                              }
                            } else {
                              newSelection.add(student.id);
                            }
                            ref.read(selectedStudentIdsProvider.notifier).state = newSelection;
                          }
                        },
                        child: Row(
                          children: [
                            if (isSelectionMode)
                              Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  final newSelection = Set<String>.from(selectedIds);
                                  if (val == true) {
                                    newSelection.add(student.id);
                                  } else {
                                    newSelection.remove(student.id);
                                    if (newSelection.isEmpty) {
                                      ref.read(isSelectionModeProvider.notifier).state = false;
                                    }
                                  }
                                  ref.read(selectedStudentIdsProvider.notifier).state = newSelection;
                                },
                              ),
                            Expanded(child: StudentListItem(student: student)),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
        floatingActionButton: isSelectionMode
            ? null
            : FloatingActionButton(
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
      ),
    );
  }

  void _handleBulkArchive(BuildContext context, WidgetRef ref, Set<String> ids, UserModel? currentUser) async {
    if (currentUser == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Students?'),
        content: Text('Are you sure you want to mark ${ids.length} students as "Left"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final students = ref.read(studentsStreamProvider).value ?? [];
      for (var id in ids) {
        final student = students.firstWhere((s) => s.id == id);
        await ref.read(studentServiceProvider).markStudentAsLeft(student, currentUser);
      }
      ref.read(isSelectionModeProvider.notifier).state = false;
      ref.read(selectedStudentIdsProvider.notifier).state = {};
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ids.length} students archived.')));
      }
    }
  }

  void _handleBulkDelete(BuildContext context, WidgetRef ref, Set<String> ids, UserModel? currentUser) async {
    if (currentUser == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Students Permanently?'),
        content: Text('This will delete ${ids.length} students forever. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Forever', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final students = ref.read(studentsStreamProvider).value ?? [];
      for (var id in ids) {
        final student = students.firstWhere((s) => s.id == id);
        await ref.read(studentServiceProvider).deleteStudent(student.id, currentUser, seatId: student.assignedSeatId);
      }
      ref.read(isSelectionModeProvider.notifier).state = false;
      ref.read(selectedStudentIdsProvider.notifier).state = {};
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ids.length} students deleted.')));
      }
    }
  }
}
