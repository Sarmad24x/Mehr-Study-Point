import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_providers.dart';
import '../domain/dashboard_stats.dart';

/// Controller provider that fetches the dashboard statistics.
final dashboardControllerProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final dashboardRepository = ref.watch(dashboardRepositoryProvider);
  return dashboardRepository.getDashboardStats();
});
