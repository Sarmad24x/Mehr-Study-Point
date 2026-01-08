import './fee.dart';

abstract class FeeRepository {
  /// Returns a list of all fee records for a specific student.
  Future<List<Fee>> getFeesForStudent(String studentId);

  /// Creates a new fee record for a student.
  Future<void> createFee(Fee fee);

  /// Updates an existing fee record (e.g., to mark as paid).
  Future<void> updateFee(Fee fee);
}
