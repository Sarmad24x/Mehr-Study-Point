import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../models/user_model.dart';
import '../../models/fee_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final stats = ref.watch(dashboardStatsProvider);

    // Run the New Month Check
    if (userProfile?.role == UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndPromptMonthlyFees(context, ref);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Streams will auto-refresh
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${userProfile?.name ?? 'User'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Total Seats',
                    value: stats.totalSeats.toString(),
                    icon: Icons.event_seat,
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Active Students',
                    value: stats.activeStudents.toString(),
                    icon: Icons.people,
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Pending Fees',
                    value: 'Rs. ${stats.pendingFees.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet,
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Available Seats',
                    value: stats.availableSeats.toString(),
                    icon: Icons.check_circle,
                    color: Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Status Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSummaryRow('Occupancy', 
                        '${stats.totalSeats > 0 ? ((stats.totalSeats - stats.availableSeats) / stats.totalSeats * 100).toStringAsFixed(1) : 0}%'),
                      const Divider(),
                      _buildSummaryRow('Current Month', DateFormat('MMMM yyyy').format(DateTime.now())),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkAndPromptMonthlyFees(BuildContext context, WidgetRef ref) async {
    final fees = ref.read(feesStreamProvider).value ?? [];
    final currentMonthStr = DateFormat('MMMM yyyy').format(DateTime.now());
    
    // Check if any 'Monthly' fee exists for this month
    final alreadyGenerated = fees.any((f) => 
      f.type == 'Monthly' && 
      DateFormat('MMMM yyyy').format(f.dueDate) == currentMonthStr
    );

    if (!alreadyGenerated && fees.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('New Month: $currentMonthStr'),
          content: const Text('Monthly fees have not been generated yet. Would you like to generate them now for all active students?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Generate Now'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final currentUser = ref.read(userProfileProvider).value;
        final students = ref.read(studentsStreamProvider).value ?? [];
        if (currentUser != null) {
          // For bulk generation, we'll use each student's specific rate
          int count = 0;
          for (var student in students) {
            if (student.status == 'Active') {
              await ref.read(feeServiceProvider).addFee(
                FeeModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString() + student.id,
                  studentId: student.id,
                  amount: student.monthlyFee,
                  paidAmount: 0.0,
                  dueDate: DateTime.now().add(const Duration(days: 5)),
                  status: FeeStatus.pending,
                  type: 'Monthly',
                ),
                currentUser,
              );
              count++;
            }
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully generated $count monthly fees!')));
          }
        }
      }
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
