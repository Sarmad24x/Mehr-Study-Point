import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import '../models/seat_model.dart';

// Stream of all seats
final seatsStreamProvider = StreamProvider<List<SeatModel>>((ref) {
  return ref.watch(seatServiceProvider).getSeatsStream();
});

// Filtered seats search
final seatSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredSeatsProvider = Provider<List<SeatModel>>((ref) {
  final seatsAsync = ref.watch(seatsStreamProvider);
  final searchQuery = ref.watch(seatSearchQueryProvider).toLowerCase();

  return seatsAsync.when(
    data: (seats) {
      if (searchQuery.isEmpty) return seats;
      return seats
          .where((seat) => seat.seatNumber.contains(searchQuery))
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
