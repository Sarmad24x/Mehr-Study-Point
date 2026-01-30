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
      backgroundColor: Theme.of(context).brightness == Brightness.light 
          ? Colors.grey[50] 
          : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Fee Management', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add, color: Colors.blue),
            tooltip: 'Generate Monthly Fees',
            onPressed: () => _showBulkGenerateDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Section - Matches Settings style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) =>
                  ref.read(feeSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search by Status or Student...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue, size: 20),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light 
                    ? Colors.white 
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

          // Summary Stats
          if (feesAsync.hasValue)
            _buildSummaryStats(feesAsync.value!),

          const SizedBox(height: 8),

          // Fees List
          Expanded(
            child: feesAsync.when(
              data: (_) {
                if (filteredFees.isEmpty) {
                  return const Center(child: Text('No fee records found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filteredFees.length,
                  itemBuilder: (context, index) {
                    final fee = filteredFees[index];
                    final student = studentsAsync.value?.firstWhere(
                      (s) => s.id == fee.studentId,
                      orElse: () => throw Exception('Student not found'),
                    );

                    return _FeeListItem(
                      fee: fee,
                      studentName: student?.fullName ?? 'Unknown Student',
                      onTap: () => _showPaymentDialog(context, ref, fee),
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

  Widget _buildSummaryStats(List<FeeModel> fees) {
    final pendingCount = fees.where((f) => f.status == FeeStatus.pending || f.status == FeeStatus.overdue).length;
    final totalPendingAmount = fees
        .where((f) => f.status != FeeStatus.paid)
        .fold(0.0, (sum, f) => sum + (f.amount - f.paidAmount));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _StatCard(
            title: 'Pending',
            value: '$pendingCount',
            icon: Icons.hourglass_top_rounded,
            color: Colors.orange,
            bgColor: Colors.orange.shade50,
          ),
          const SizedBox(width: 12),
          _StatCard(
            title: 'Owed Amount',
            value: 'Rs. ${totalPendingAmount.toInt()}',
            icon: Icons.payments_outlined,
            color: Colors.blue,
            bgColor: Colors.blue.shade50,
          ),
        ],
      ),
    );
  }

  void _showBulkGenerateDialog(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(userProfileProvider).value;
    final students = ref.read(studentsStreamProvider).value ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Generate Fees', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will create monthly fee records for all ACTIVE students using their individual set rates.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Record Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text('Remaining Balance: Rs. $remaining', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount Paid',
                      prefixText: 'Rs. ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: InputDecoration(
                      labelText: 'Payment Method', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Cash', 'EasyPaisa', 'JazzCash', 'Bank Transfer']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedMethod = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
                      child: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light ? bgColor : Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _FeeListItem extends StatelessWidget {
  final FeeModel fee;
  final String studentName;
  final VoidCallback onTap;

  const _FeeListItem({
    required this.fee,
    required this.studentName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = fee.amount - fee.paidAmount;
    
    Color statusColor;
    IconData statusIcon;
    Color iconBgColor;

    switch (fee.status) {
      case FeeStatus.paid:
        statusColor = Colors.green.shade700;
        iconBgColor = Colors.green.shade50;
        statusIcon = Icons.check_circle_outline;
        break;
      case FeeStatus.pending:
        statusColor = Colors.orange.shade700;
        iconBgColor = Colors.orange.shade50;
        statusIcon = Icons.hourglass_empty;
        break;
      case FeeStatus.overdue:
        statusColor = Colors.red.shade700;
        iconBgColor = Colors.red.shade50;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case FeeStatus.partial:
        statusColor = Colors.blue.shade700;
        iconBgColor = Colors.blue.shade50;
        statusIcon = Icons.account_balance_wallet_outlined;
        break;
    }

    if (Theme.of(context).brightness == Brightness.dark) {
       iconBgColor = statusColor.withOpacity(0.15);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(statusIcon, color: statusColor, size: 22),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          '${fee.type} • Rs. ${fee.amount.toInt()} • Due: ${DateFormat('dd MMM').format(fee.dueDate)}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _StatusChip(status: fee.status),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Owed: Rs. ${remaining.toInt()}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
          ],
        ),
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
      case FeeStatus.paid: color = Colors.green; break;
      case FeeStatus.pending: color = Colors.orange; break;
      case FeeStatus.overdue: color = Colors.red; break;
      case FeeStatus.partial: color = Colors.blue; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
