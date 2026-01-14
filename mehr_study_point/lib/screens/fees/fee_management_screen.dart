import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/fee_model.dart';
import '../../providers/service_providers.dart';

class FeeManagementScreen extends ConsumerWidget {
  const FeeManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(feesStreamProvider);
    final filteredFees = ref.watch(filteredFeesProvider);
    final studentsAsync = ref.watch(studentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) =>
                  ref.read(feeSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search by Status or Student ID...',
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
      body: feesAsync.when(
        data: (_) {
          if (filteredFees.isEmpty) {
            return const Center(child: Text('No fee records found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredFees.length,
            itemBuilder: (context, index) {
              final fee = filteredFees[index];
              final student = studentsAsync.value?.firstWhere(
                (s) => s.id == fee.studentId,
                orElse: () => throw Exception('Student not found'),
              );

              return Card(
                child: ListTile(
                  title: Text(student?.fullName ?? 'Unknown Student'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${fee.type} | Amount: Rs. ${fee.amount}'),
                      Text(
                        'Due: ${DateFormat('dd MMM yyyy').format(fee.dueDate)}',
                        style: TextStyle(
                          color: fee.status == FeeStatus.overdue
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: _StatusChip(status: fee.status),
                  onTap: () => _showPaymentDialog(context, ref, fee),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, FeeModel fee) {
    final controller = TextEditingController(text: fee.amount.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount paid by student:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount Paid',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              await ref.read(feeServiceProvider).markAsPaid(fee.id, amount);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
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
      case FeeStatus.paid:
        color = Colors.green;
        break;
      case FeeStatus.pending:
        color = Colors.orange;
        break;
      case FeeStatus.overdue:
        color = Colors.red;
        break;
      case FeeStatus.partial:
        color = Colors.blue;
        break;
    }

    return Chip(
      label: Text(
        status.name.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
