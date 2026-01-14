import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/fee_providers.dart';
import '../domain/fee.dart';
import 'add_fee_screen.dart';
import 'fee_list_controller.dart';

class FeeListScreen extends ConsumerWidget {
  final String studentId;
  final String studentName;

  const FeeListScreen({super.key, required this.studentId, required this.studentName});

  Color _getColorForStatus(FeeStatus status) {
    switch (status) {
      case FeeStatus.paid:
        return Colors.green;
      case FeeStatus.pending:
        return Colors.orange;
      case FeeStatus.overdue:
        return Colors.red;
    }
  }

  Future<void> _markAsPaid(BuildContext context, WidgetRef ref, Fee fee) async {
    final updatedFee = Fee(
      id: fee.id,
      studentId: fee.studentId,
      amount: fee.amount,
      dueDate: fee.dueDate,
      status: FeeStatus.paid,
      paidDate: DateTime.now(),
    );

    try {
      await ref.read(feeRepositoryProvider).updateFee(updatedFee);
      ref.invalidate(feeListControllerProvider(studentId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fee marked as paid.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update fee: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(feeListControllerProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Fee History for $studentName'),
      ),
      body: feesAsync.when(
        data: (fees) {
          if (fees.isEmpty) {
            return const Center(child: Text('No fee records found for this student.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(feeListControllerProvider(studentId).future),
            child: ListView.builder(
              itemCount: fees.length,
              itemBuilder: (context, index) {
                final fee = fees[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getColorForStatus(fee.status),
                      child: Icon(fee.status == FeeStatus.paid ? Icons.check : Icons.receipt, color: Colors.white),
                    ),
                    title: Text('Amount: \$${fee.amount.toStringAsFixed(2)}'),
                    subtitle: Text('Due: ${DateFormat.yMMMd().format(fee.dueDate)}\nStatus: ${fee.status.toString().split('.').last.toUpperCase()}'),
                    trailing: fee.status != FeeStatus.paid
                        ? TextButton(
                            onPressed: () => _markAsPaid(context, ref, fee),
                            child: const Text('Mark as Paid'),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddFeeScreen(studentId: studentId, studentName: studentName),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Manual Fee',
      ),
    );
  }
}
