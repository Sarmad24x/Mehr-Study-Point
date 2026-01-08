import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalSeats;
  final int reservedSeats;
  final int availableSeats;
  final double totalFeesCollectedThisMonth;
  final double pendingFeesAmount;
  final int newStudentsThisMonth;

  const DashboardStats({
    required this.totalSeats,
    required this.reservedSeats,
    required this.availableSeats,
    required this.totalFeesCollectedThisMonth,
    required this.pendingFeesAmount,
    required this.newStudentsThisMonth,
  });

  @override
  List<Object?> get props => [
        totalSeats,
        reservedSeats,
        availableSeats,
        totalFeesCollectedThisMonth,
        pendingFeesAmount,
        newStudentsThisMonth,
      ];
}
