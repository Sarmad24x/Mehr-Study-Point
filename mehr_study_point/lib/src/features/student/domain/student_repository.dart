import './student.dart';

abstract class StudentRepository {
  /// Returns a list of all students.
  Future<List<Student>> getStudents();

  /// Returns a single student by their ID.
  Future<Student> getStudent(String id);

  /// Creates a new student record.
  Future<void> createStudent(Student student);

  /// Updates an existing student record.
  Future<void> updateStudent(Student student);

  /// Deletes a student record by their ID.
  Future<void> deleteStudent(String id);
}
