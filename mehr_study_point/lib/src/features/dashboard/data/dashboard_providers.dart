import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/dashboard_repository.dart';
import 'supabase_dashboard_repository.dart';

///
/// Provider for the [DashboardRepository]
///
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseDashboardRepository(supabaseClient);
});
