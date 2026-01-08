import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seat_assignment_providers.dart';
import '../../seat/domain/seat.dart';
import '../../student/domain/student.dart';
import 'seat_assignment_controller.dart';

class SeatAssignmentScreen extends ConsumerWidget {
  const SeatAssignmentScreen({super.key});

  Future<void> _assignSeat(BuildContext context, WidgetRef ref, {required String studentId, required String seatId}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Assignment'),
        content: const Text('Are you sure you want to assign this seat?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Assign')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(seatAssignmentRepositoryProvider).assignSeat(studentId: studentId, seatId: seatId);
        ref.invalidate(seatAssignmentControllerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seat assigned successfully!'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign seat: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentDataAsync = ref.watch(seatAssignmentControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seat Assignment (Drag & Drop)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(seatAssignmentControllerProvider),
          ),
        ],
      ),
      body: assignmentDataAsync.when(
        data: (data) {
          if (data.availableSeats.isEmpty) {
            return const Center(child: Text('No available seats.'));
          }
          if (data.unassignedStudents.isEmpty) {
            return const Center(child: Text('All students have been assigned a seat.'));
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSeatList(context, ref, data.availableSeats),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _buildStudentList(context, ref, data.unassignedStudents),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStudentList(BuildContext context, WidgetRef ref, List<Student> students) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Unassigned Students (${students.length})', style: Theme.of(context).textTheme.titleLarge),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Draggable<Student>(
                data: student,
                feedback: Card(
                  elevation: 8.0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(student.fullName, style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                childWhenDragging: ListTile(
                  title: Text(student.fullName),
                  leading: const Icon(Icons.person, color: Colors.grey),
                ),
                child: ListTile(
                  title: Text(student.fullName),
                  subtitle: Text(student.contactNumber),
                  leading: const Icon(Icons.person),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSeatList(BuildContext context, WidgetRef ref, List<Seat> seats) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Available Seats (${seats.length})', style: Theme.of(context).textTheme.titleLarge),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: seats.length,
            itemBuilder: (context, index) {
              final seat = seats[index];
              return DragTarget<Student>(
                builder: (context, candidateData, rejectedData) {
                  final isTargeted = candidateData.isNotEmpty;
                  return ListTile(
                    tileColor: isTargeted ? Colors.green.withOpacity(0.2) : null,
                    title: Text('Seat ${seat.seatNumber}'),
                    subtitle: seat.zone != null ? Text('Zone: ${seat.zone}') : null,
                    leading: Icon(
                      Icons.chair,
                      color: isTargeted ? Colors.green : Colors.grey,
                    ),
                  );
                },
                onWillAccept: (student) => true,
                onAccept: (student) {
                  _assignSeat(context, ref, studentId: student.id, seatId: seat.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
