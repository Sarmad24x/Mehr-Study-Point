import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/seat.dart';
import '../domain/seat_repository.dart';

class SupabaseSeatRepository implements SeatRepository {
  final SupabaseClient _client;
  final String _table = 'seats';
  final String _boxName = 'seats_box';

  SupabaseSeatRepository(this._client);

  Future<Box<Seat>> _getBox() async {
    return await Hive.openBox<Seat>(_boxName);
  }

  @override
  Future<List<Seat>> getSeats() async {
    try {
      final response = await _client.from(_table).select().order('seat_number', ascending: true);
      final seats = (response as List).map((item) => Seat.fromMap(item)).toList();
      
      // Update local cache
      final box = await _getBox();
      await box.clear();
      for (var s in seats) {
        await box.put(s.id, s);
      }
      
      return seats;
    } catch (e) {
      // Fallback to local cache
      final box = await _getBox();
      if (box.isNotEmpty) {
        return box.values.toList()..sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
      }
      throw Exception('Failed to get seats: $e');
    }
  }

  @override
  Future<void> updateSeatStatus(String seatId, SeatStatus status) async {
    try {
      // 1. Update remote
      await _client.from(_table).update({'status': status.toString().split('.').last}).eq('id', seatId);
      
      // 2. Update local cache
      final box = await _getBox();
      final seat = box.get(seatId);
      if (seat != null) {
        final updatedSeat = Seat(
          id: seat.id,
          seatNumber: seat.seatNumber,
          status: status,
          zone: seat.zone,
          studentId: seat.studentId,
        );
        await box.put(seatId, updatedSeat);
      }
    } catch (e) {
      throw Exception('Failed to update seat status: $e');
    }
  }

  @override
  Future<void> updateMultipleSeatStatuses(List<String> seatIds, SeatStatus status) async {
    try {
      // 1. Update remote
      await _client
          .from(_table)
          .update({'status': status.toString().split('.').last})
          .inFilter('id', seatIds);
          
      // 2. Update local cache
      final box = await _getBox();
      for (var id in seatIds) {
        final seat = box.get(id);
        if (seat != null) {
          final updatedSeat = Seat(
            id: seat.id,
            seatNumber: seat.seatNumber,
            status: status,
            zone: seat.zone,
            studentId: seat.studentId,
          );
          await box.put(id, updatedSeat);
        }
      }
    } catch (e) {
      throw Exception('Failed to update multiple seat statuses: $e');
    }
  }

  @override
  Future<void> addSeats(int count) async {
    try {
      // 1. Get the current highest seat number
      final response = await _client
          .from(_table)
          .select('seat_number')
          .order('seat_number', ascending: false)
          .limit(1)
          .maybeSingle();
      
      int nextSeatNumber = 1;
      if (response != null) {
        nextSeatNumber = (response['seat_number'] as int) + 1;
      }

      // 2. Prepare new seats
      final List<Map<String, dynamic>> newSeats = [];
      for (int i = 0; i < count; i++) {
        newSeats.add({
          'seat_number': nextSeatNumber + i,
          'status': 'available',
        });
      }

      // 3. Insert into Supabase
      await _client.from(_table).insert(newSeats);
    } catch (e) {
      throw Exception('Failed to add more seats: $e');
    }
  }
}
