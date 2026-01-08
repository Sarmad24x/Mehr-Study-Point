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

  @override
  void didUpdateWidget(covariant SeatManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear selection if filter or search changes
    if (_isSelectionMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _clearSelection());
    }
  }

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
    final filteredSeats = ref.watch(filteredSeatsProvider);

    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildDefaultAppBar(),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: seatsAsync.when(
              data: (_) {
                if (filteredSeats.isEmpty) {
                  return const Center(child: Text('No seats match the current criteria.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(seatListControllerProvider.future),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: filteredSeats.length,
                    itemBuilder: (context, index) {
                      final seat = filteredSeats[index];
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
          ),
        ],
      ),
    );
  }

  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: TextField(
        onChanged: (value) => ref.read(seatSearchQueryProvider.notifier).state = value,
        decoration: const InputDecoration(
          hintText: 'Search Seat Number...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
      ),
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
          icon: const Icon(Icons.event_available, color: Colors.greenAccent),
          tooltip: 'Mark as Available',
          onPressed: () => _updateMultipleSeats(SeatStatus.available),
        ),
        IconButton(
          icon: const Icon(Icons.build, color: Colors.orangeAccent),
          tooltip: 'Mark as Maintenance',
          onPressed: () => _updateMultipleSeats(SeatStatus.maintenance),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final currentFilter = ref.watch(seatStatusFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: SeatStatus.values.map((status) {
          return FilterChip(
            label: Text(status.toString().split('.').last.toUpperCase()),
            selected: currentFilter == status,
            onSelected: (isSelected) {
              ref.read(seatStatusFilterProvider.notifier).state = isSelected ? status : null;
            },
          );
        }).toList(),
      ),
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
