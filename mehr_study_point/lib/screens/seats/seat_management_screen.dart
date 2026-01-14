import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/seat_provider.dart';
import '../../models/seat_model.dart';

class SeatManagementScreen extends ConsumerWidget {
  const SeatManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seatsAsync = ref.watch(seatsStreamProvider);
    final filteredSeats = ref.watch(filteredSeatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seat Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) =>
                  ref.read(seatSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search Seat Number...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: seatsAsync.when(
        data: (_) {
          if (filteredSeats.isEmpty) {
            return const Center(child: Text('No seats found.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filteredSeats.length,
            itemBuilder: (context, index) {
              final seat = filteredSeats[index];
              return _SeatWidget(seat: seat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SeatWidget extends StatelessWidget {
  final SeatModel seat;
  const _SeatWidget({required this.seat});

  Color _getStatusColor() {
    switch (seat.status) {
      case SeatStatus.available:
        return Colors.green;
      case SeatStatus.reserved:
        return Colors.red;
      case SeatStatus.maintenance:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Show seat details / assignment dialog
      },
      child: Container(
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.1),
          border: Border.all(color: _getStatusColor(), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat, color: _getStatusColor()),
            const SizedBox(height: 4),
            Text(
              seat.seatNumber,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
