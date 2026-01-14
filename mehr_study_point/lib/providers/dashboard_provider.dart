import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'seat_provider.dart';
import 'student_provider.dart';
import 'fee_provider.dart';
import '../models/seat_model.dart';
import '../models/fee_model.dart';

class DashboardStats {
  final int totalSeats;
  final int activeStudents;
  final double pendingFees;
  final int availableSeats;

  DashboardStats({
    required this.totalSeats,
    required this.activeStudents,
    required this.pendingFees,
    required this.availableSeats,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final seats = ref.watch(seatsStreamProvider).value ?? [];
  final students = ref.watch(studentsStreamProvider).value ?? [];
  final fees = ref.watch(feesStreamProvider).value ?? [];

  final totalSeats = seats.length;
  final availableSeats = seats.where((s) => s.status == SeatStatus.available).length;
  final activeStudents = students.where((s) => s.status == 'Active').length;
  
  final pendingFees = fees
      .where((f) => f.status != FeeStatus.paid)
      .fold(0.0, (sum, f) => sum + (f.amount - f.paidAmount));

  return DashboardStats(
    totalSeats: totalSeats,
    activeStudents: activeStudents,
    pendingFees: pendingFees,
    availableSeats: availableSeats,
  );
});
