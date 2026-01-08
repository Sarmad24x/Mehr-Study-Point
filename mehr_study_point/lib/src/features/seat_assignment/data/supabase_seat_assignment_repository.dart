import 'package:supabase_flutter/supabase_flutter.dart';

import '../../seat/domain/seat.dart';
import '../../student/domain/student.dart';
import '../domain/seat_assignment_repository.dart';

class SupabaseSeatAssignmentRepository implements SeatAssignmentRepository {
  final SupabaseClient _client;

  SupabaseSeatAssignmentRepository(this._client);

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
    // TODO: This should be a single transaction using a Postgres Function (RPC).
    try {
      // 1. Update the student's record
      await _client.from('students').update({'assigned_seat_id': seatId}).eq('id', studentId);

      // 2. Update the seat's record
      await _client
          .from('seats')
          .update({'student_id': studentId, 'status': 'reserved'}).eq('id', seatId);
    } catch (e) {
      throw Exception('Failed to assign seat: $e');
    }
  }

  @override
  Future<void> unassignSeat({required String studentId, required String seatId}) async {
    // TODO: This should be a single transaction using a Postgres Function (RPC).
    try {
      // 1. Update the student's record
      await _client.from('students').update({'assigned_seat_id': null}).eq('id', studentId);

      // 2. Update the seat's record
      await _client.from('seats').update({'student_id': null, 'status': 'available'}).eq('id', seatId);
    } catch (e) {
      throw Exception('Failed to unassign seat: $e');
    }
  }
}
