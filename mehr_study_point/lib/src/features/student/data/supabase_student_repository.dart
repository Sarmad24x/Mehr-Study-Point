import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/student.dart';
import '../domain/student_repository.dart';

class SupabaseStudentRepository implements StudentRepository {
  final SupabaseClient _client;
  final String _table = 'students';

  SupabaseStudentRepository(this._client);

  @override
  Future<void> createStudent(Student student) async {
    try {
      await _client.from(_table).insert(student.toMap());
    } catch (e) {
      // TODO: Handle exceptions more gracefully
      throw Exception('Failed to create student: $e');
    }
  }

  @override
  Future<Student> getStudent(String id) async {
    try {
      final response = await _client.from(_table).select().eq('id', id).single();

      return Student.fromMap(response);
    } catch (e) {
      throw Exception('Failed to get student: $e');
    }
  }

  @override
  Future<List<Student>> getStudents() async {
    try {
      final response = await _client.from(_table).select();

      return (response as List).map((item) => Student.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to get students: $e');
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    try {
      await _client.from(_table).update(student.toMap()).eq('id', student.id);
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  @override
  Future<void> deleteStudent(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }
}
