import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/seat_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';
import '../../models/seat_model.dart';

class SeatManagementScreen extends ConsumerStatefulWidget {
  const SeatManagementScreen({super.key});

  @override
  ConsumerState<SeatManagementScreen> createState() => _SeatManagementScreenState();
}

class _SeatManagementScreenState extends ConsumerState<SeatManagementScreen> {
  final Set<String> _selectedSeatIds = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedSeatIds.contains(id)) {
        _selectedSeatIds.remove(id);
        if (_selectedSeatIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedSeatIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final seatsAsync = ref.watch(seatsStreamProvider);
    final filteredSeats = ref.watch(filteredSeatsProvider);
    final currentUser = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedSeatIds.length} Selected' : 'Seat Management'),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.edit_attributes),
              onPressed: () => _showBulkUpdateDialog(context, ref, currentUser),
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _selectedSeatIds.clear();
                _isSelectionMode = false;
              }),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              _buildSummaryHeader(filteredSeats),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  onChanged: (value) =>
                      ref.read(seatSearchQueryProvider.notifier).state = value,
                  decoration: InputDecoration(
                    hintText: 'Search Seat Number...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
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
              final isSelected = _selectedSeatIds.contains(seat.id);

              return _SeatWidget(
                seat: seat,
                isSelected: isSelected,
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(seat.id);
                  } else {
                    _showSeatActionDialog(context, seat);
                  }
                },
                onLongPress: () => _toggleSelection(seat.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSummaryHeader(List<SeatModel> seats) {
    final available = seats.where((s) => s.status == SeatStatus.available).length;
    final reserved = seats.where((s) => s.status == SeatStatus.reserved).length;
    final maintenance = seats.where((s) => s.status == SeatStatus.maintenance).length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Available', available, Colors.green),
          _buildSummaryItem('Reserved', reserved, Colors.red),
          _buildSummaryItem('Repair', maintenance, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _showBulkUpdateDialog(BuildContext context, WidgetRef ref, dynamic currentUser) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Update Selected Seats Status', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Mark as Available'),
            onTap: () => _applyBulkStatus(ref, SeatStatus.available, currentUser),
          ),
          ListTile(
            leading: const Icon(Icons.build, color: Colors.orange),
            title: const Text('Mark as Maintenance'),
            onTap: () => _applyBulkStatus(ref, SeatStatus.maintenance, currentUser),
          ),
        ],
      ),
    );
  }

  void _applyBulkStatus(WidgetRef ref, SeatStatus status, dynamic currentUser) async {
    if (currentUser == null) return;
    await ref.read(seatServiceProvider).bulkUpdateSeats(_selectedSeatIds.toList(), status, currentUser);
    setState(() {
      _selectedSeatIds.clear();
      _isSelectionMode = false;
    });
    if (mounted) Navigator.pop(context);
  }

  void _showSeatActionDialog(BuildContext context, SeatModel seat) {
    // Implement seat details/assignment/hold logic here
  }
}

class _SeatWidget extends StatelessWidget {
  final SeatModel seat;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SeatWidget({
    required this.seat,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  Color _getStatusColor() {
    switch (seat.status) {
      case SeatStatus.available: return Colors.green;
      case SeatStatus.reserved: return Colors.red;
      case SeatStatus.maintenance: return Colors.orange;
      case SeatStatus.held: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat, color: isSelected ? Colors.white : color),
            const SizedBox(height: 4),
            Text(
              seat.seatNumber,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
