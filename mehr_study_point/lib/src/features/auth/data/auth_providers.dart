import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/auth_repository.dart';
import 'supabase_auth_repository.dart';

///
/// Provider for the [AuthRepository]
///
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(supabaseClient);
});
