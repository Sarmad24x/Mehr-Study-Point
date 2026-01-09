import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/dashboard_repository.dart';
import '../domain/dashboard_stats.dart';

class SupabaseDashboardRepository implements DashboardRepository {
  final SupabaseClient _client;

  SupabaseDashboardRepository(this._client);

  @override
  Future<DashboardStats> getDashboardStats() async {
    // TODO: This is a perfect use case for a single RPC (database function) call for performance.
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      // Fetch stats in parallel
      final results = await Future.wait([
        _client.from('seats').select('status'),
        _client
            .from('fees')
            .select('amount')
            .eq('status', 'paid')
            .gte('paid_date', firstDayOfMonth.toIso8601String()),
        _client.from('fees').select('amount').inFilter('status', ['pending', 'overdue']),
        _client.from('students').select('id').gte('admission_date', firstDayOfMonth.toIso8601String()),
      ]);

      // Process seats data
      final seatsData = results[0] as List;
      final totalSeats = seatsData.length;
      final reservedSeats = seatsData.where((s) => s['status'] == 'reserved').length;
      final availableSeats = totalSeats - reservedSeats;

      // Process fees collected data
      final feesCollectedData = results[1] as List;
      final totalFeesCollectedThisMonth =
          feesCollectedData.fold<double>(0, (sum, item) => sum + (item['amount'] as num));

      // Process pending fees data
      final pendingFeesData = results[2] as List;
      final pendingFeesAmount =
          pendingFeesData.fold<double>(0, (sum, item) => sum + (item['amount'] as num));

      // Process new students data
      final newStudentsThisMonth = (results[3] as List).length;

      return DashboardStats(
        totalSeats: totalSeats,
        reservedSeats: reservedSeats,
        availableSeats: availableSeats,
        totalFeesCollectedThisMonth: totalFeesCollectedThisMonth,
        pendingFeesAmount: pendingFeesAmount,
        newStudentsThisMonth: newStudentsThisMonth,
      );
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }
}
