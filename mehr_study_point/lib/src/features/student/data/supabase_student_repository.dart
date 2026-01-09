import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/audit_repository.dart';
import '../../../core/domain/audit_log.dart';
import '../domain/student.dart';
import '../domain/student_repository.dart';

class SupabaseStudentRepository implements StudentRepository {
  final SupabaseClient _client;
  final AuditRepository _auditRepository;
  final String _table = 'students';
  final String _boxName = 'students_box';

  SupabaseStudentRepository(this._client, this._auditRepository);

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<Box<Student>> _getBox() async {
    return await Hive.openBox<Student>(_boxName);
  }

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
      // 1. Update local cache immediately for high responsiveness
      final box = await _getBox();
      await box.put(student.id, student);

      // 2. Update remote
      await _client.from(_table).insert(student.toMap());
      
      // 3. Log action
      await _logAction(
        actionType: AuditAction.create,
        recordId: student.id,
        newValues: student.toMap(),
      );
    } catch (e) {
      // TODO: Add to a sync queue if offline
      throw Exception('Failed to create student: $e');
    }
  }

  @override
  Future<Student> getStudent(String id) async {
    try {
      final response = await _client.from(_table).select().eq('id', id).single();
      final student = Student.fromMap(response);
      
      // Update local cache
      final box = await _getBox();
      await box.put(student.id, student);
      
      return student;
    } catch (e) {
      // Fallback to local cache
      final box = await _getBox();
      final localStudent = box.get(id);
      if (localStudent != null) return localStudent;
      
      throw Exception('Failed to get student (and no local cache): $e');
    }
  }

  @override
  Future<List<Student>> getStudents() async {
    try {
      final response = await _client.from(_table).select();
      final students = (response as List).map((item) => Student.fromMap(item)).toList();
      
      // Update local cache: clear and refill
      final box = await _getBox();
      await box.clear();
      for (var s in students) {
        await box.put(s.id, s);
      }
      
      return students;
    } catch (e) {
      // Fallback to local cache
      final box = await _getBox();
      if (box.isNotEmpty) {
        return box.values.toList();
      }
      throw Exception('Failed to get students (and no local cache): $e');
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    try {
      // 1. Update local cache
      final box = await _getBox();
      await box.put(student.id, student);

      // 2. Update remote
      await _client.from(_table).update(student.toMap()).eq('id', student.id);
      
      // 3. Log action
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
      // 1. Update local cache
      final box = await _getBox();
      await box.delete(id);

      // 2. Update remote
      await _client.from(_table).delete().eq('id', id);
      
      // 3. Log action
      await _logAction(
        actionType: AuditAction.delete,
        recordId: id,
      );
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }
}
