import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fee_providers.dart';
import '../domain/fee.dart';

/// Provider to fetch the list of fees for a specific student.
final feeListControllerProvider = FutureProvider.autoDispose.family<List<Fee>, String>((ref, studentId) async {
  final feeRepository = ref.watch(feeRepositoryProvider);
  return feeRepository.getFeesForStudent(studentId);
});
