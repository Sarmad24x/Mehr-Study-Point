import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seat_providers.dart';
import '../domain/seat.dart';
import 'seat_list_controller.dart';

class SeatManagementScreen extends ConsumerStatefulWidget {
  const SeatManagementScreen({super.key});

  @override
  ConsumerState<SeatManagementScreen> createState() => _SeatManagementScreenState();
}

class _SeatManagementScreenState extends ConsumerState<SeatManagementScreen> {
  final Set<String> _selectedSeatIds = {};

  bool get _isSelectionMode => _selectedSeatIds.isNotEmpty;

  void _onSeatTap(Seat seat) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedSeatIds.contains(seat.id)) {
          _selectedSeatIds.remove(seat.id);
        } else {
          _selectedSeatIds.add(seat.id);
        }
      });
    } else {
      _showSeatDetails(context, seat);
    }
  }

  void _onSeatLongPress(Seat seat) {
    if (!_isSelectionMode) {
      setState(() {
        _selectedSeatIds.add(seat.id);
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedSeatIds.clear();
    });
  }

  Color _getColorForStatus(SeatStatus status, {bool isSelected = false}) {
    if (isSelected) return Colors.blue.shade300;
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

  Future<void> _updateMultipleSeats(SeatStatus status) async {
    try {
      await ref.read(seatRepositoryProvider).updateMultipleSeatStatuses(_selectedSeatIds.toList(), status);
      ref.invalidate(seatListControllerProvider);
      _clearSelection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update seats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seatsAsync = ref.watch(seatListControllerProvider);

    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildDefaultAppBar(),
      body: seatsAsync.when(
        data: (seats) {
          if (seats.isEmpty) {
            return const Center(child: Text('No seats found.'));
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
                final isSelected = _selectedSeatIds.contains(seat.id);
                return Card(
                  elevation: isSelected ? 8.0 : 2.0,
                  color: _getColorForStatus(seat.status, isSelected: isSelected),
                  child: InkWell(
                    onTap: () => _onSeatTap(seat),
                    onLongPress: () => _onSeatLongPress(seat),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            seat.seatNumber.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(Icons.check_circle, color: Colors.white, size: 18),
                          ),
                      ],
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

  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: const Text('Seat Management'),
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      title: Text('${_selectedSeatIds.length} selected'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.event_available, color: Colors.green),
          tooltip: 'Mark as Available',
          onPressed: () => _updateMultipleSeats(SeatStatus.available),
        ),
        IconButton(
          icon: const Icon(Icons.build, color: Colors.orange),
          tooltip: 'Mark as Maintenance',
          onPressed: () => _updateMultipleSeats(SeatStatus.maintenance),
        ),
      ],
    );
  }

  void _showSeatDetails(BuildContext context, Seat seat) {
     showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              title: Text('Seat ${seat.seatNumber}', style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text('Status: ${seat.status.toString().split('.').last.toUpperCase()}'),
            ),
            const Divider(),
            if (seat.status != SeatStatus.available)
              ListTile(
                leading: const Icon(Icons.event_available, color: Colors.green),
                title: const Text('Mark as Available'),
                onTap: () => _updateSingleSeatStatus(context, seat.id, SeatStatus.available),
              ),
            if (seat.status != SeatStatus.maintenance)
              ListTile(
                leading: const Icon(Icons.build, color: Colors.orange),
                title: const Text('Mark as Maintenance'),
                onTap: () => _updateSingleSeatStatus(context, seat.id, SeatStatus.maintenance),
              ),
          ],
        );
      },
    );
  }

  Future<void> _updateSingleSeatStatus(BuildContext context, String seatId, SeatStatus status) async {
    Navigator.of(context).pop();
    try {
      await ref.read(seatRepositoryProvider).updateSeatStatus(seatId, status);
      ref.invalidate(seatListControllerProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update seat: $e')),
        );
      }
    }
  }
}
