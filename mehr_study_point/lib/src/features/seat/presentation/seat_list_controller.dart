import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seat_providers.dart';
import '../domain/seat.dart';

/// Provider to fetch the original, unfiltered list of seats from the repository.
final seatListControllerProvider = FutureProvider.autoDispose<List<Seat>>((ref) async {
  final seatRepository = ref.watch(seatRepositoryProvider);
  return seatRepository.getSeats();
});

/// Provider for the current status filter. A `null` value means no filter (show all).
final seatStatusFilterProvider = StateProvider<SeatStatus?>((ref) => null);

/// Provider for the current search query by seat number.
final seatSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider that returns a filtered and searched list of seats.
/// It watches the original list, the filter, and the search query, then returns the processed list.
final filteredSeatsProvider = Provider.autoDispose<List<Seat>>((ref) {
  final seatsAsyncValue = ref.watch(seatListControllerProvider);
  final filter = ref.watch(seatStatusFilterProvider);
  final searchQuery = ref.watch(seatSearchQueryProvider);

  // When the async value is available, filter and search the data.
  if (seatsAsyncValue.hasValue) {
    List<Seat> seats = seatsAsyncValue.value!;

    // Apply status filter
    if (filter != null) {
      seats = seats.where((seat) => seat.status == filter).toList();
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      seats = seats.where((seat) => seat.seatNumber.toString().contains(searchQuery)).toList();
    }

    return seats;
  }

  // Return an empty list while loading or if there's an error.
  // The UI will use the main `seatListControllerProvider` to show loading/error states.
  return [];
});
