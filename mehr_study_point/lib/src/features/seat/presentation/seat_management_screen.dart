import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/seat.dart';
import 'seat_list_controller.dart';

class SeatManagementScreen extends ConsumerWidget {
  const SeatManagementScreen({super.key});

  Color _getColorForStatus(SeatStatus status) {
    switch (status) {
      case SeatStatus.reserved:
        return Colors.red.shade300;
      case SeatStatus.maintenance:
        return Colors.yellow.shade300;
      case SeatStatus.available:
      default:
        return Colors.green.shade300;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seatsAsync = ref.watch(seatListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seat Management'),
      ),
      body: seatsAsync.when(
        data: (seats) {
          if (seats.isEmpty) {
            return const Center(child: Text('No seats found. Have you seeded the database?'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(seatListControllerProvider.future),
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // 5 seats per row
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: seats.length,
              itemBuilder: (context, index) {
                final seat = seats[index];
                return Card(
                  color: _getColorForStatus(seat.status),
                  child: InkWell(
                    onTap: () {
                      // TODO: Show seat details and actions
                    },
                    child: Center(
                      child: Text(
                        seat.seatNumber.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
