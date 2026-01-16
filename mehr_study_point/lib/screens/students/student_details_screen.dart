import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/student_model.dart';
import '../../models/seat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/seat_provider.dart';
import 'add_student_screen.dart';

class StudentDetailsScreen extends ConsumerWidget {
  final StudentModel student;
  const StudentDetailsScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddStudentScreen(student: student),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, ref, currentUser),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  student.fullName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(context),
            const SizedBox(height: 24),
            _buildSeatCard(context, ref, currentUser),
            const SizedBox(height: 24),
            _buildGuardianCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildDetailRow('Full Name', student.fullName),
            _buildDetailRow('Contact', student.contactNumber),
            _buildDetailRow('Address', student.address),
            _buildDetailRow('Admission', DateFormat('dd MMM yyyy').format(student.admissionDate)),
            _buildDetailRow('Status', student.status),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatCard(BuildContext context, WidgetRef ref, dynamic currentUser) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_seat, color: Colors.blue),
        title: const Text('Assigned Seat', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Seat Number: ${student.assignedSeatNumber ?? 'Not Assigned'}'),
        trailing: TextButton(
          onPressed: () => _showSwapDialog(context, ref, currentUser),
          child: const Text('SWAP'),
        ),
      ),
    );
  }

  void _showSwapDialog(BuildContext context, WidgetRef ref, dynamic currentUser) {
    if (currentUser == null) return;

    final seatsAsync = ref.watch(seatsStreamProvider);
    final availableSeats = seatsAsync.value?.where((s) => s.status == SeatStatus.available).toList() ?? [];

    showDialog(
      context: context,
      builder: (context) {
        SeatModel? selectedNewSeat;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Swap Seat'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Moving ${student.fullName} from Seat ${student.assignedSeatNumber}'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SeatModel>(
                    decoration: const InputDecoration(labelText: 'Select New Seat', border: OutlineInputBorder()),
                    value: selectedNewSeat,
                    items: availableSeats.map((s) => DropdownMenuItem(value: s, child: Text('Seat ${s.seatNumber}'))).toList(),
                    onChanged: (val) => setState(() => selectedNewSeat = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: selectedNewSeat == null
                      ? null
                      : () async {
                          final oldSeat = seatsAsync.value?.firstWhere((s) => s.id == student.assignedSeatId);
                          if (oldSeat != null) {
                            await ref.read(seatServiceProvider).swapSeat(
                                  student: student,
                                  oldSeat: oldSeat,
                                  newSeat: selectedNewSeat!,
                                  currentUser: currentUser,
                                );
                            if (context.mounted) {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Go back to student list to refresh state
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Seat swapped successfully')),
                              );
                            }
                          }
                        },
                  child: const Text('Confirm Swap'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGuardianCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guardian Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildDetailRow('Name', student.guardianName ?? 'N/A'),
            _buildDetailRow('Contact', student.guardianContact ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic currentUser) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student?'),
        content: const Text('This action cannot be undone. The seat will be marked as available.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && currentUser != null) {
      await ref.read(studentServiceProvider).deleteStudent(
            student.id,
            currentUser,
            seatId: student.assignedSeatId,
          );
      if (context.mounted) {
        Navigator.pop(context); // Close details screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student deleted')),
        );
      }
    }
  }
}
