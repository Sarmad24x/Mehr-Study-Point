import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/seat_assignment_repository.dart';
import 'supabase_seat_assignment_repository.dart';

///
/// Provider for the [SeatAssignmentRepository]
///
final seatAssignmentRepositoryProvider = Provider<SeatAssignmentRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final auditRepository = ref.watch(auditRepositoryProvider);
  return SupabaseSeatAssignmentRepository(supabaseClient, auditRepository);
});
