import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/report_service.dart';
import 'add_student_screen.dart';
import 'student_detail_screen.dart';
import 'student_list_controller.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentListControllerProvider);
    final filteredStudents = ref.watch(filteredStudentsProvider);
    final connectivityAsync = ref.watch(connectivityProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (value) => ref.read(studentSearchQueryProvider.notifier).state = value,
          decoration: const InputDecoration(
            hintText: 'Search Name or Number...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          studentsAsync.when(
            data: (students) => IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Export CSV',
              onPressed: () => ReportService.exportStudentsToCsv(students),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConnectivityBanner(connectivityAsync),
          Expanded(
            child: studentsAsync.when(
              data: (_) {
                if (filteredStudents.isEmpty) {
                  return const Center(child: Text('No students found matching your search.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(studentListControllerProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredStudents.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(student.fullName[0].toUpperCase()),
                        ),
                        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(student.contactNumber),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => StudentDetailScreen(studentId: student.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddStudentScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildConnectivityBanner(AsyncValue<List<ConnectivityResult>> connectivityAsync) {
    return connectivityAsync.when(
      data: (results) {
        final isOffline = results.contains(ConnectivityResult.none);
        if (isOffline) {
          return Container(
            color: Colors.orange.shade800,
            padding: const EdgeInsets.symmetric(vertical: 4),
            width: double.infinity,
            child: const Text(
              'Offline Mode - Using Cached Data',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
