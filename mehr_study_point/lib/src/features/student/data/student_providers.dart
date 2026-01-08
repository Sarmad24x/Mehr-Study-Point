import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/student_repository.dart';
import 'supabase_student_repository.dart';

///
/// Provider for the [StudentRepository]
///
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseStudentRepository(supabaseClient);
});
