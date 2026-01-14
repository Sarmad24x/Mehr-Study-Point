import './seat.dart';

abstract class SeatRepository {
  /// Returns a list of all seats.
  Future<List<Seat>> getSeats();

  /// Updates the status of a single seat.
  Future<void> updateSeatStatus(String seatId, SeatStatus status);

  /// Updates the status of multiple seats.
  Future<void> updateMultipleSeatStatuses(List<String> seatIds, SeatStatus status);

  /// Adds a specified number of new seats to the library.
  Future<void> addSeats(int count);
}
