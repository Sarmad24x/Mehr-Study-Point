import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/audit_repository.dart';
import '../../../core/domain/audit_log.dart';
import '../domain/student.dart';
import '../domain/student_repository.dart';

class SupabaseStudentRepository implements StudentRepository {
  final SupabaseClient _client;
  final AuditRepository _auditRepository;
  final String _table = 'students';

  SupabaseStudentRepository(this._client, this._auditRepository);

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<void> _logAction({
    required AuditAction actionType,
    required String recordId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    if (_currentUserId != null) {
      await _auditRepository.log(AuditLog(
        userId: _currentUserId!,
        actionType: actionType,
        tableName: _table,
        recordId: recordId,
        oldValues: oldValues,
        newValues: newValues,
        timestamp: DateTime.now(),
      ));
    }
  }

  @override
  Future<void> createStudent(Student student) async {
    try {
      await _client.from(_table).insert(student.toMap());
      await _logAction(
        actionType: AuditAction.create,
        recordId: student.id,
        newValues: student.toMap(),
      );
    } catch (e) {
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
      // For more accurate logging, we should ideally fetch the old values here.
      // For now, we'll just log the new state.
      await _client.from(_table).update(student.toMap()).eq('id', student.id);
      await _logAction(
        actionType: AuditAction.update,
        recordId: student.id,
        newValues: student.toMap(),
      );
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  @override
  Future<void> deleteStudent(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
      await _logAction(
        actionType: AuditAction.delete,
        recordId: id,
      );
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }
}
