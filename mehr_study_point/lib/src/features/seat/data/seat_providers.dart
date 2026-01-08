import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/seat_repository.dart';
import 'supabase_seat_repository.dart';

///
/// Provider for the [SeatRepository]
///
final seatRepositoryProvider = Provider<SeatRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseSeatRepository(supabaseClient);
});
