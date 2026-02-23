import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import 'auth_provider.dart';
import '../models/student_model.dart';

final studentsStreamProvider = StreamProvider.autoDispose<List<StudentModel>>((ref) {
  // Restart stream on auth state change
  ref.watch(authStateProvider);
  
  return ref.watch(studentServiceProvider).getStudentsStream();
});

final studentSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final studentStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => 'Active'); // Default to Active

final filteredStudentsProvider = Provider.autoDispose<List<StudentModel>>((ref) {
  final studentsAsync = ref.watch(studentsStreamProvider);
  final searchQuery = ref.watch(studentSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(studentStatusFilterProvider);

  return studentsAsync.when(
    data: (students) {
      return students.where((student) {
        final matchesSearch = student.fullName.toLowerCase().contains(searchQuery) ||
            student.contactNumber.contains(searchQuery) ||
            (student.assignedSeatNumber?.contains(searchQuery) ?? false);
        
        final matchesStatus = statusFilter == null || student.status == statusFilter;
        
        return matchesSearch && matchesStatus;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
