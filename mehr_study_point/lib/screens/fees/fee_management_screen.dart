import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/fee_model.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Generate Monthly Fees',
            onPressed: () => _showBulkGenerateDialog(context, ref),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) =>
                  ref.read(feeSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search by Status or Student...',
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

              final remaining = fee.amount - fee.paidAmount;

              return Card(
                child: ListTile(
                  title: Text(student?.fullName ?? 'Unknown Student'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${fee.type} | Total: Rs. ${fee.amount}'),
                      if (remaining > 0)
                        Text('Owed: Rs. $remaining', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      if (fee.paymentMethod != null)
                        Text('Via: ${fee.paymentMethod}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      Text(
                        'Due: ${DateFormat('dd MMM yyyy').format(fee.dueDate)}',
                        style: TextStyle(
                          color: fee.status == FeeStatus.overdue ? Colors.red : Colors.grey,
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

  void _showBulkGenerateDialog(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(userProfileProvider).value;
    final students = ref.read(studentsStreamProvider).value ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Monthly Fees'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This will create monthly fee records for all ACTIVE students using their individual set rates.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (currentUser == null) return;
              final count = await ref.read(feeServiceProvider).generateMonthlyFees(
                students, 
                DateTime.now().add(const Duration(days: 5)), 
                currentUser,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated $count fee records!')));
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, FeeModel fee) {
    final remaining = fee.amount - fee.paidAmount;
    final controller = TextEditingController(text: remaining.toString());
    final notesController = TextEditingController();
    String? selectedMethod = 'Cash';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Record Payment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Student owes Rs. $remaining', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid Now',
                        border: OutlineInputBorder(),
                        prefixText: 'Rs. ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                      items: ['Cash', 'EasyPaisa', 'JazzCash', 'Bank Transfer']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedMethod = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final currentUser = ref.read(userProfileProvider).value;
                    if (currentUser == null) return;

                    final amount = double.tryParse(controller.text) ?? 0;
                    await ref.read(feeServiceProvider).markAsPaid(
                      fee: fee,
                      newPaymentAmount: amount,
                      currentUser: currentUser,
                      method: selectedMethod,
                      notes: notesController.text.trim(),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Confirm Payment'),
                ),
              ],
            );
          },
        );
      },
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

    return Chip(
      label: Text(status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
