import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/settings_repository.dart';
import 'supabase_settings_repository.dart';

///
/// Provider for the [SettingsRepository]
///
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseSettingsRepository(supabaseClient);
});
