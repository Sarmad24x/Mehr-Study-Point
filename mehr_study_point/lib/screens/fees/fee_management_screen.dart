
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/fee_model.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';
import 'widgets/stat_card.dart';
import 'widgets/fee_list_item.dart';
import 'widgets/record_payment_bottom_sheet.dart';

class FeeManagementScreen extends ConsumerWidget {
  const FeeManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(feesStreamProvider);
    final filteredFees = ref.watch(filteredFeesProvider);
    final studentsAsync = ref.watch(studentsStreamProvider);
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.grey[50]
          : null,
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text('Fee Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
          // Search Bar
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
          if (feesAsync.hasValue) _buildSummaryStats(feesAsync.value!),

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
                    final student = studentsAsync.value
                        ?.where((s) => s.id == fee.studentId)
                        .firstOrNull;

                    return FeeListItem(
                      fee: fee,
                      studentName: student?.fullName ?? 'Deleted Student',
                      onTap: () => _showPaymentBottomSheet(context, fee),
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
    final pendingCount = fees
        .where((f) => f.status == FeeStatus.pending || f.status == FeeStatus.overdue)
        .length;
    final totalPendingAmount = fees
        .where((f) => f.status != FeeStatus.paid)
        .fold(0.0, (sum, f) => sum + (f.amount - f.paidAmount));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          StatCard(
            title: 'Pending',
            value: '$pendingCount',
            icon: Icons.hourglass_top_rounded,
            color: Colors.orange,
            bgColor: Colors.orange.shade50,
          ),
          const SizedBox(width: 12),
          StatCard(
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
        title:
            const Text('Generate Fees', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This will create monthly fee records for all ACTIVE students using their individual set rates.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              if (currentUser == null) return;
              final count = await ref.read(feeServiceProvider).generateMonthlyFees(
                    students,
                    DateTime.now().add(const Duration(days: 5)),
                    currentUser,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Generated $count fee records!')));
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showPaymentBottomSheet(BuildContext context, FeeModel fee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => RecordPaymentBottomSheet(fee: fee),
    );
  }
}
