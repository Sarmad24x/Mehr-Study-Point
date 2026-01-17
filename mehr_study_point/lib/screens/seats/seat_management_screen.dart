import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/seat_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../models/seat_model.dart';
import '../../models/fee_model.dart';
import '../../models/student_model.dart';
import '../students/add_student_screen.dart';
import '../students/student_details_screen.dart';

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
    final zones = ref.watch(seatZonesProvider);

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
          preferredSize: const Size.fromHeight(160),
          child: Column(
            children: [
              _buildSummaryHeader(filteredSeats),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
              _buildFilterChips(zones),
            ],
          ),
        ),
      ),
      body: seatsAsync.when(
        data: (_) {
          if (filteredSeats.isEmpty) {
            return const Center(child: Text('No seats match filters.'));
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

  Widget _buildFilterChips(List<String> zones) {
    final activeStatus = ref.watch(seatStatusFilterProvider);
    final activeZone = ref.watch(seatZoneFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Status Chips
          ...SeatStatus.values.map((status) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(status.name),
              selected: activeStatus == status,
              onSelected: (val) => ref.read(seatStatusFilterProvider.notifier).state = val ? status : null,
            ),
          )),
          // Zone Chips
          ...zones.map((zone) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(zone),
              selected: activeZone == zone,
              onSelected: (val) => ref.read(seatZoneFilterProvider.notifier).state = val ? zone : null,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(List<SeatModel> seats) {
    final available = seats.where((s) => s.status == SeatStatus.available).length;
    final reserved = seats.where((s) => s.status == SeatStatus.reserved).length;
    final held = seats.where((s) => s.status == SeatStatus.held).length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Available', available, Colors.green),
          _buildSummaryItem('Reserved', reserved, Colors.red),
          _buildSummaryItem('Held', held, Colors.blue),
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
    final students = ref.read(studentsStreamProvider).value ?? [];
    final allFees = ref.read(feesStreamProvider).value ?? [];
    final currentUser = ref.read(userProfileProvider).value;

    showDialog(
      context: context,
      builder: (context) {
        if (seat.status == SeatStatus.reserved && seat.studentId != null) {
          final student = students.firstWhere((s) => s.id == seat.studentId, orElse: () => throw 'Student not found');
          final hasOverdue = allFees.any((f) => f.studentId == student.id && f.status == FeeStatus.overdue);

          return AlertDialog(
            title: Row(
              children: [
                Text('Seat ${seat.seatNumber}'),
                const Spacer(),
                if (hasOverdue) const Icon(Icons.warning, color: Colors.red),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Occupied by: ${student.fullName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Contact: ${student.contactNumber}'),
                if (hasOverdue)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('⚠️ HAS OVERDUE FEES', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => StudentDetailsScreen(student: student)));
                },
                child: const Text('View Profile'),
              ),
            ],
          );
        }

        if (seat.status == SeatStatus.held) {
          return AlertDialog(
            title: Text('Seat ${seat.seatNumber} - On Hold'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('This seat is temporarily held.'),
                if (seat.holdExpiresAt != null)
                  Text('Expires on: ${DateFormat('dd MMM').format(seat.holdExpiresAt!)}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(seatServiceProvider).updateSeatStatus(seat.id, SeatStatus.available);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Release Hold'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text('Seat ${seat.seatNumber} - ${seat.status.name.toUpperCase()}'),
          content: Text(seat.status == SeatStatus.available 
            ? 'This seat is currently available for enrollment.' 
            : 'This seat is under maintenance.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            if (seat.status == SeatStatus.available) ...[
              TextButton(
                onPressed: () => _showAssignExistingDialog(context, ref, seat, students, currentUser),
                child: const Text('Assign Existing'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStudentScreen()));
                },
                child: const Text('Enroll New'),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showAssignExistingDialog(BuildContext context, WidgetRef ref, SeatModel seat, List<StudentModel> students, dynamic currentUser) {
    // Show students who don't have a seat assigned
    final eligibleStudents = students.where((s) => s.assignedSeatId == null && s.status == 'Active').toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Existing Student'),
        content: eligibleStudents.isEmpty 
          ? const Text('No active students without seats found.')
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: eligibleStudents.length,
                itemBuilder: (context, index) {
                  final student = eligibleStudents[index];
                  return ListTile(
                    title: Text(student.fullName),
                    subtitle: Text(student.contactNumber),
                    onTap: () async {
                      if (currentUser != null) {
                        // We use the swapSeat logic but oldSeat is null-safe 
                        // Or we can just update seat and student directly
                        await ref.read(studentServiceProvider).updateStudent(
                          student.copyWith(assignedSeatId: seat.id, assignedSeatNumber: seat.seatNumber),
                          currentUser
                        );
                        await ref.read(seatServiceProvider).updateSeatStatus(seat.id, SeatStatus.reserved, studentId: student.id);
                        if (context.mounted) {
                          Navigator.pop(context); // Close student picker
                          Navigator.pop(context); // Close seat dialog
                        }
                      }
                    },
                  );
                },
              ),
            ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
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
