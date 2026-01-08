import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../seat/domain/seat.dart';
import '../../student/domain/student.dart';
import '../data/seat_assignment_providers.dart';

/// A simple data class to hold the data for the seat assignment screen.
class SeatAssignmentData {
  final List<Student> unassignedStudents;
  final List<Seat> availableSeats;

  SeatAssignmentData({
    required this.unassignedStudents,
    required this.availableSeats,
  });
}

/// Controller provider that fetches both unassigned students and available seats.
final seatAssignmentControllerProvider = FutureProvider.autoDispose<SeatAssignmentData>((ref) async {
  final repository = ref.watch(seatAssignmentRepositoryProvider);

  // Fetch both lists in parallel for efficiency.
  final studentsFuture = repository.getUnassignedStudents();
  final seatsFuture = repository.getAvailableSeats();

  // Wait for both API calls to complete.
  final results = await Future.wait([studentsFuture, seatsFuture]);

  return SeatAssignmentData(
    unassignedStudents: results[0] as List<Student>,
    availableSeats: results[1] as List<Seat>,
  );
});
