import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seat_providers.dart';
import '../domain/seat.dart';

final seatListControllerProvider = FutureProvider.autoDispose<List<Seat>>((ref) async {
  final seatRepository = ref.watch(seatRepositoryProvider);
  return seatRepository.getSeats();
});
