import '../../seat/domain/seat.dart';
import '../../student/domain/student.dart';

abstract class SeatAssignmentRepository {
  /// Returns a list of all active students who do not have an assigned seat.
  Future<List<Student>> getUnassignedStudents();

  /// Returns a list of all seats with the status 'available'.
  Future<List<Seat>> getAvailableSeats();

  /// Assigns a specific seat to a specific student.
  /// This should ideally be a single transaction on the backend.
  Future<void> assignSeat({required String studentId, required String seatId});

  /// Unassigns a seat from a student, making the seat available again.
  Future<void> unassignSeat({required String studentId, required String seatId});
}
