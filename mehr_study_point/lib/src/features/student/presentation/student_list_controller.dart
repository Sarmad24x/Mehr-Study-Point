import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_providers.dart';
import '../domain/student.dart';

/// Provider for the full list of students from the repository.
final studentListControllerProvider = FutureProvider.autoDispose<List<Student>>((ref) async {
  final studentRepository = ref.watch(studentRepositoryProvider);
  return studentRepository.getStudents();
});

/// Provider for the current search query.
final studentSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for the filtered list of students based on the search query.
final filteredStudentsProvider = Provider.autoDispose<List<Student>>((ref) {
  final studentsAsyncValue = ref.watch(studentListControllerProvider);
  final searchQuery = ref.watch(studentSearchQueryProvider).toLowerCase();

  if (studentsAsyncValue.hasValue) {
    final students = studentsAsyncValue.value!;
    if (searchQuery.isEmpty) return students;

    return students.where((student) {
      return student.fullName.toLowerCase().contains(searchQuery) ||
             student.contactNumber.contains(searchQuery);
    }).toList();
  }
  return [];
});
