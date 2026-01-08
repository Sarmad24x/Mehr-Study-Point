import './dashboard_stats.dart';

abstract class DashboardRepository {
  /// Returns a snapshot of the current dashboard statistics.
  Future<DashboardStats> getDashboardStats();
}
