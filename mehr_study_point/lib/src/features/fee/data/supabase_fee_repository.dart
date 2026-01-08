import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/fee.dart';
import '../domain/fee_repository.dart';

class SupabaseFeeRepository implements FeeRepository {
  final SupabaseClient _client;
  final String _table = 'fees';

  SupabaseFeeRepository(this._client);

  @override
  Future<void> createFee(Fee fee) async {
    try {
      await _client.from(_table).insert(fee.toMap());
    } catch (e) {
      throw Exception('Failed to create fee: $e');
    }
  }

  @override
  Future<List<Fee>> getFeesForStudent(String studentId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('student_id', studentId)
          .order('due_date', ascending: false);
      return (response as List).map((item) => Fee.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to get fees for student: $e');
    }
  }

  @override
  Future<void> updateFee(Fee fee) async {
    try {
      await _client.from(_table).update(fee.toMap()).eq('id', fee.id);
    } catch (e) {
      throw Exception('Failed to update fee: $e');
    }
  }
}
