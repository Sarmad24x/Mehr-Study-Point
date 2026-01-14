import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import '../models/student_model.dart';

final studentsStreamProvider = StreamProvider<List<StudentModel>>((ref) {
  return ref.watch(studentServiceProvider).getStudentsStream();
});

final studentSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredStudentsProvider = Provider<List<StudentModel>>((ref) {
  final studentsAsync = ref.watch(studentsStreamProvider);
  final searchQuery = ref.watch(studentSearchQueryProvider).toLowerCase();

  return studentsAsync.when(
    data: (students) {
      if (searchQuery.isEmpty) return students;
      return students.where((student) {
        return student.fullName.toLowerCase().contains(searchQuery) ||
            student.contactNumber.contains(searchQuery) ||
            (student.assignedSeatNumber?.contains(searchQuery) ?? false);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
