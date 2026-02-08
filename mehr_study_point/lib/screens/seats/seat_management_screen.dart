
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
import '../../models/user_model.dart';
import '../students/add_student_screen.dart';
import '../students/student_details_screen.dart';
import 'widgets/seat_widget.dart';
import 'widgets/seat_status_filter_chip.dart';
import 'widgets/seat_zone_filter_chip.dart';

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

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final seatsAsync = ref.watch(seatsStreamProvider);
    final filteredSeats = ref.watch(filteredSeatsProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final isAdmin = userProfile?.role == UserRole.admin;
    final zones = ref.watch(seatZonesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light 
          ? Colors.grey[50] 
          : null,
      appBar: AppBar(
        //automaticallyImplyLeading: false, // This removes the back button
        title: Text(
          _isSelectionMode ? '${_selectedSeatIds.length} Selected' : 'Seat Management',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (!_isSelectionMode && isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add New Seat',
              onPressed: () => _showAddSeatDialog(context, ref, userProfile!),
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.edit_attributes),
              onPressed: () => _showBulkUpdateDialog(context, ref, userProfile),
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Header
          _buildSummaryHeader(filteredSeats),
          
          const SizedBox(height: 8),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) =>
                  ref.read(seatSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search Seat Number...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueGrey, size: 24),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light 
                    ? Colors.grey[100] 
                    : Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                ...SeatStatus.values.map((status) => Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: SeatStatusFilterChip(
                    label: status == SeatStatus.maintenance ? 'Maintenance' : _capitalize(status.name),
                    value: status,
                  ),
                )),
                if (zones.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(height: 20, child: VerticalDivider(width: 1)),
                  ),
                ...zones.map((zone) => Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: SeatZoneFilterChip(
                    label: _capitalize(zone),
                    value: zone,
                  ),
                )),
              ],
            ),
          ),

          Expanded(
            child: seatsAsync.when(
              data: (_) {
                if (filteredSeats.isEmpty) {
                  return const Center(child: Text('No seats match filters.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredSeats.length,
                  itemBuilder: (context, index) {
                    final seat = filteredSeats[index];
                    final isSelected = _selectedSeatIds.contains(seat.id);

                    return SeatWidget(
                      seat: seat,
                      isSelected: isSelected,
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(seat.id);
                        } else {
                          _showSeatActionDialog(context, seat);
                        }
                      },
                      onLongPress: () {
                        if (isAdmin) _toggleSelection(seat.id);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(List<SeatModel> seats) {
    final available = seats.where((s) => s.status == SeatStatus.available).length;
    final reserved = seats.where((s) => s.status == SeatStatus.reserved).length;
    final held = seats.where((s) => s.status == SeatStatus.held).length;
    final maintenance = seats.where((s) => s.status == SeatStatus.maintenance).length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem(available.toString(), 'AVAILABLE', const Color(0xFF2ECC71)),
          _buildSummaryItem(reserved.toString(), 'RESERVED', const Color(0xFFE74C3C)),
          _buildSummaryItem(held.toString(), 'HELD', const Color(0xFF3498DB)),
          _buildSummaryItem(maintenance.toString(), 'REPAIR', const Color(0xFFE67E22)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 22,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  void _showAddSeatDialog(BuildContext context, WidgetRef ref, UserModel currentUser) {
    final numberController = TextEditingController();
    final zoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Seat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberController,
              decoration: const InputDecoration(labelText: 'Seat Number (e.g. 161)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: zoneController,
              decoration: const InputDecoration(labelText: 'Zone (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (numberController.text.isNotEmpty) {
                await ref.read(seatServiceProvider).addSeat(
                  numberController.text.trim(),
                  zoneController.text.trim().isEmpty ? null : zoneController.text.trim(),
                  currentUser,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add Seat'),
          ),
        ],
      ),
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
    final userProfile = ref.read(userProfileProvider).value;
    final isAdmin = userProfile?.role == UserRole.admin;

    showDialog(
      context: context,
      builder: (context) {
        if (seat.status == SeatStatus.reserved && seat.studentId != null) {
          final student = students.firstWhere((s) => s.id == seat.studentId, orElse: () => throw 'Student not found');
          final hasOverdue = allFees.any((f) => f.studentId == student.id && f.status == FeeStatus.overdue);

          return AlertDialog(
            title: Row(
              children: [
                Expanded(child: Text('Seat ${seat.seatNumber}')),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(seat.status == SeatStatus.available 
                ? 'This seat is currently available for enrollment.' 
                : 'This seat is under maintenance.'),
              if (isAdmin) ...[
                const Divider(),
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete Seat permanently', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Seat?'),
                        content: const Text('Are you sure you want to remove this seat from the system?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(seatServiceProvider).deleteSeat(seat.id, userProfile!);
                      if (context.mounted) {
                        Navigator.pop(context); // Close action dialog
                      }
                    }
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            if (seat.status == SeatStatus.available) ...[
              TextButton(
                onPressed: () => _showAssignExistingDialog(context, ref, seat, students, userProfile),
                child: const Text('Assign Existing'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStudentScreen()));
                },
                child: const Text('Enroll New'),
              ),
            ] else if (seat.status == SeatStatus.maintenance && isAdmin) ...[
              ElevatedButton(
                onPressed: () async {
                  await ref.read(seatServiceProvider).updateSeatStatus(seat.id, SeatStatus.available);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Mark Available'),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showAssignExistingDialog(BuildContext context, WidgetRef ref, SeatModel seat, List<StudentModel> students, dynamic currentUser) {
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
                        await ref.read(studentServiceProvider).updateStudent(
                          student.copyWith(assignedSeatId: seat.id, assignedSeatNumber: seat.seatNumber),
                          currentUser
                        );
                        await ref.read(seatServiceProvider).updateSeatStatus(seat.id, SeatStatus.reserved, studentId: student.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
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
