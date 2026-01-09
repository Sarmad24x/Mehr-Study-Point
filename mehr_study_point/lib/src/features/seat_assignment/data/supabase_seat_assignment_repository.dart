import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/audit_repository.dart';
import '../../../core/domain/audit_log.dart';
import '../../seat/domain/seat.dart';
import '../../student/domain/student.dart';
import '../domain/seat_assignment_repository.dart';

class SupabaseSeatAssignmentRepository implements SeatAssignmentRepository {
  final SupabaseClient _client;
  final AuditRepository _auditRepository;

  SupabaseSeatAssignmentRepository(this._client, this._auditRepository);

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<void> _logAction({
    required AuditAction actionType,
    required String tableName,
    required String recordId,
    Map<String, dynamic>? newValues,
  }) async {
    if (_currentUserId != null) {
      await _auditRepository.log(AuditLog(
        userId: _currentUserId!,
        actionType: actionType,
        tableName: tableName,
        recordId: recordId,
        newValues: newValues,
        timestamp: DateTime.now(),
      ));
    }
  }

  @override
  Future<List<Student>> getUnassignedStudents() async {
    try {
      final response = await _client
          .from('students')
          .select()
          .is_('assigned_seat_id', null)
          .eq('is_active', true);
      return (response as List).map((item) => Student.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to get unassigned students: $e');
    }
  }

  @override
  Future<List<Seat>> getAvailableSeats() async {
    try {
      final response = await _client.from('seats').select().eq('status', 'available');
      return (response as List).map((item) => Seat.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to get available seats: $e');
    }
  }

  @override
  Future<void> assignSeat({required String studentId, required String seatId}) async {
    try {
      // 1. Update the student's record
      await _client.from('students').update({'assigned_seat_id': seatId}).eq('id', studentId);

      // 2. Update the seat's record
      await _client
          .from('seats')
          .update({'student_id': studentId, 'status': 'reserved'}).eq('id', seatId);

      // 3. Log the assignment
      await _logAction(
        actionType: AuditAction.update,
        tableName: 'assignments',
        recordId: studentId,
        newValues: {'student_id': studentId, 'seat_id': seatId, 'action': 'assign'},
      );
    } catch (e) {
      throw Exception('Failed to assign seat: $e');
    }
  }

  @override
  Future<void> unassignSeat({required String studentId, required String seatId}) async {
    try {
      // 1. Update the student's record
      await _client.from('students').update({'assigned_seat_id': null}).eq('id', studentId);

      // 2. Update the seat's record
      await _client.from('seats').update({'student_id': null, 'status': 'available'}).eq('id', seatId);

      // 3. Log the unassignment
      await _logAction(
        actionType: AuditAction.update,
        tableName: 'assignments',
        recordId: studentId,
        newValues: {'student_id': studentId, 'seat_id': seatId, 'action': 'unassign'},
      );
    } catch (e) {
      throw Exception('Failed to unassign seat: $e');
    }
  }
}
