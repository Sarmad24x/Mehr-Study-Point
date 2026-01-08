import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/fee_repository.dart';
import 'supabase_fee_repository.dart';

///
/// Provider for the [FeeRepository]
///
final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseFeeRepository(supabaseClient);
});
