import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import '../models/seat_model.dart';

// Stream of all seats
final seatsStreamProvider = StreamProvider<List<SeatModel>>((ref) {
  return ref.watch(seatServiceProvider).getSeatsStream();
});

// Filtering States
final seatSearchQueryProvider = StateProvider<String>((ref) => '');
final seatStatusFilterProvider = StateProvider<SeatStatus?>((ref) => null);
final seatZoneFilterProvider = StateProvider<String?>((ref) => null);

final filteredSeatsProvider = Provider<List<SeatModel>>((ref) {
  final seatsAsync = ref.watch(seatsStreamProvider);
  final searchQuery = ref.watch(seatSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(seatStatusFilterProvider);
  final zoneFilter = ref.watch(seatZoneFilterProvider);

  return seatsAsync.when(
    data: (seats) {
      return seats.where((seat) {
        final matchesSearch = seat.seatNumber.contains(searchQuery);
        final matchesStatus = statusFilter == null || seat.status == statusFilter;
        final matchesZone = zoneFilter == null || seat.zone == zoneFilter;
        return matchesSearch && matchesStatus && matchesZone;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Available Zones Provider
final seatZonesProvider = Provider<List<String>>((ref) {
  final seats = ref.watch(seatsStreamProvider).value ?? [];
  final zones = seats.map((s) => s.zone).whereType<String>().toSet().toList();
  zones.sort();
  return zones;
});
