import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/student_model.dart';
import '../../models/fee_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/seat_provider.dart';
import '../../providers/fee_provider.dart';
import 'add_student_screen.dart';
import '../../models/seat_model.dart';

class StudentDetailsScreen extends ConsumerWidget {
  final StudentModel student;
  const StudentDetailsScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProfileProvider).value;
    final feesAsync = ref.watch(feesStreamProvider);
    final isArchived = student.status == 'Archived';

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[50] : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Student Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (!isArchived)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(isArchived),
            const SizedBox(height: 32),
            
            _buildSection('PERSONAL INFORMATION', [
              _DetailTile(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: student.fullName,
              ),
              _DetailTile(
                icon: Icons.phone_android_outlined,
                label: 'Contact',
                value: student.contactNumber,
              ),
              _DetailTile(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: student.address,
              ),
              _DetailTile(
                icon: Icons.calendar_today_outlined,
                label: 'Admission Date',
                value: DateFormat('dd MMM yyyy').format(student.admissionDate),
              ),
              if (isArchived && student.leaveDate != null)
                _DetailTile(
                  icon: Icons.exit_to_app_outlined,
                  label: 'Left Date',
                  value: DateFormat('dd MMM yyyy').format(student.leaveDate!),
                  valueColor: Colors.red,
                ),
            ]),

            const SizedBox(height: 24),
            _buildSection('SUBSCRIPTION & SEAT', [
              _DetailTile(
                icon: Icons.payments_outlined,
                label: 'Monthly Fee Rate',
                value: 'Rs. ${student.monthlyFee.toInt()}',
              ),
              _DetailTile(
                icon: Icons.event_seat_outlined,
                label: 'Assigned Seat',
                value: 'Seat ${student.assignedSeatNumber ?? 'N/A'}',
                trailing: !isArchived ? TextButton(
                  onPressed: () => _showSwapDialog(context, ref, currentUser),
                  child: const Text('SWAP', style: TextStyle(fontWeight: FontWeight.bold)),
                ) : null,
              ),
            ]),

            const SizedBox(height: 24),
            _buildSection('GUARDIAN DETAILS', [
              _DetailTile(
                icon: Icons.people_outline,
                label: 'Guardian Name',
                value: student.guardianName ?? 'N/A',
              ),
              _DetailTile(
                icon: Icons.contact_phone_outlined,
                label: 'Guardian Contact',
                value: student.guardianContact ?? 'N/A',
              ),
            ]),

            const SizedBox(height: 24),
            _buildFeeHistory(feesAsync),

            const SizedBox(height: 32),
            if (!isArchived)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmArchive(context, ref, currentUser),
                  icon: const Icon(Icons.archive_outlined, color: Colors.orange),
                  label: const Text('MARK AS LEFT (ARCHIVE)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isArchived) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isArchived ? Colors.grey.shade200 : Colors.orange.shade100,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person, 
                  size: 60, 
                  color: isArchived ? Colors.grey : Colors.orange
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isArchived ? Colors.grey.shade700 : Colors.green.shade600,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  student.status.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          student.fullName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          'Student ID: ${student.id.substring(0, 8).toUpperCase()}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.1),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildFeeHistory(AsyncValue<List<FeeModel>> feesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'PAYMENT HISTORY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.1),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: feesAsync.when(
            data: (allFees) {
              final studentFees = allFees.where((f) => f.studentId == student.id).toList();
              if (studentFees.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text('No payment records found.', style: TextStyle(color: Colors.grey))),
                );
              }
              // Sort by date descending
              studentFees.sort((a, b) => b.dueDate.compareTo(a.dueDate));
              
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: studentFees.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final fee = studentFees[index];
                  return ListTile(
                    title: Text('${fee.type} Fee', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(DateFormat('MMMM yyyy').format(fee.dueDate), style: const TextStyle(fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Rs. ${fee.amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        _StatusChip(status: fee.status),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Error loading history: $e'),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmArchive(BuildContext context, WidgetRef ref, dynamic currentUser) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Archive Student?'),
        content: const Text('This will mark the student as "Left", free up their assigned seat, and preserve their history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm == true && currentUser != null) {
      await ref.read(studentServiceProvider).markStudentAsLeft(student, currentUser);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student archived successfully')));
      }
    }
  }

  void _showSwapDialog(BuildContext context, WidgetRef ref, dynamic currentUser) {
    if (currentUser == null) return;
    final seatsAsync = ref.watch(seatsStreamProvider);
    final availableSeats = seatsAsync.value?.where((s) => s.status == SeatStatus.available).toList() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        SeatModel? selectedNewSeat;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Swap Student Seat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Moving from Seat ${student.assignedSeatNumber} to:', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<SeatModel>(
                    decoration: InputDecoration(
                      labelText: 'Select New Seat',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: selectedNewSeat,
                    items: availableSeats.map((s) => DropdownMenuItem(value: s, child: Text('Seat ${s.seatNumber}'))).toList(),
                    onChanged: (val) => setState(() => selectedNewSeat = val),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: selectedNewSeat == null ? null : () async {
                        final oldSeat = seatsAsync.value?.firstWhere((s) => s.id == student.assignedSeatId);
                        if (oldSeat != null) {
                          await ref.read(seatServiceProvider).swapSeat(
                            student: student,
                            oldSeat: oldSeat,
                            newSeat: selectedNewSeat!,
                            currentUser: currentUser,
                          );
                          if (context.mounted) {
                            Navigator.pop(context); // Close sheet
                            Navigator.pop(context); // Go back to list to refresh
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seat swapped successfully')));
                          }
                        }
                      },
                      child: const Text('CONFIRM SWAP', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic currentUser) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Permanently?'),
        content: const Text('This action cannot be undone. All data related to this student will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Forever', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && currentUser != null) {
      await ref.read(studentServiceProvider).deleteStudent(student.id, currentUser, seatId: student.assignedSeatId);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student records deleted')));
      }
    }
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.blue.shade700, size: 20),
      ),
      title: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      subtitle: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: valueColor)),
      trailing: trailing,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final FeeStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case FeeStatus.paid: color = Colors.green; break;
      case FeeStatus.pending: color = Colors.orange; break;
      case FeeStatus.overdue: color = Colors.red; break;
      case FeeStatus.partial: color = Colors.blue; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
