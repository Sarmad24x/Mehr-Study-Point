import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_providers.dart';
import '../domain/student.dart';

final studentListControllerProvider = FutureProvider.autoDispose<List<Student>>((ref) async {
  final studentRepository = ref.watch(studentRepositoryProvider);
  return studentRepository.getStudents();
});
