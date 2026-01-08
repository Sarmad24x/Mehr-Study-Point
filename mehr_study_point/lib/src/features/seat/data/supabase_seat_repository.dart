import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/seat.dart';
import '../domain/seat_repository.dart';

class SupabaseSeatRepository implements SeatRepository {
  final SupabaseClient _client;
  final String _table = 'seats';

  SupabaseSeatRepository(this._client);

  @override
  Future<List<Seat>> getSeats() async {
    try {
      final response = await _client.from(_table).select().order('seat_number', ascending: true);
      return (response as List).map((item) => Seat.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to get seats: $e');
    }
  }

  @override
  Future<void> updateSeatStatus(String seatId, SeatStatus status) async {
    try {
      await _client.from(_table).update({'status': status.toString().split('.').last}).eq('id', seatId);
    } catch (e) {
      throw Exception('Failed to update seat status: $e');
    }
  }

  @override
  Future<void> updateMultipleSeatStatuses(List<String> seatIds, SeatStatus status) async {
    try {
      await _client
          .from(_table)
          .update({'status': status.toString().split('.').last})
          .in_('id', seatIds);
    } catch (e) {
      throw Exception('Failed to update multiple seat statuses: $e');
    }
  }
}
