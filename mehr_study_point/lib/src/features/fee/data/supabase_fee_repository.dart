import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/fee.dart';
import '../domain/fee_repository.dart';

class SupabaseFeeRepository implements FeeRepository {
  final SupabaseClient _client;
  final String _table = 'fees';
  final String _boxName = 'fees_box';

  SupabaseFeeRepository(this._client);

  Future<Box<Fee>> _getBox() async {
    return await Hive.openBox<Fee>(_boxName);
  }

  @override
  Future<void> createFee(Fee fee) async {
    try {
      // 1. Update local cache
      final box = await _getBox();
      await box.put(fee.id, fee);

      // 2. Update remote
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
      final fees = (response as List).map((item) => Fee.fromMap(item)).toList();
      
      // Update local cache
      final box = await _getBox();
      // We only store fees for this student in a filtered way or use studentId as part of key
      // For simplicity here, we'll store all fees in the box and filter locally on fallback
      for (var f in fees) {
        await box.put(f.id, f);
      }
      
      return fees;
    } catch (e) {
      // Fallback to local cache
      final box = await _getBox();
      if (box.isNotEmpty) {
        return box.values
            .where((f) => f.studentId == studentId)
            .toList()
          ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
      }
      throw Exception('Failed to get fees: $e');
    }
  }

  @override
  Future<void> updateFee(Fee fee) async {
    try {
      // 1. Update local cache
      final box = await _getBox();
      await box.put(fee.id, fee);

      // 2. Update remote
      await _client.from(_table).update(fee.toMap()).eq('id', fee.id);
    } catch (e) {
      throw Exception('Failed to update fee: $e');
    }
  }
}
