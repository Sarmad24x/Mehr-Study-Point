import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/data/auth_providers.dart';
import '../../seat/presentation/seat_management_screen.dart';
import '../../seat_assignment/presentation/seat_assignment_screen.dart';
import '../../student/presentation/student_list_screen.dart';
import '../domain/dashboard_stats.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Stats',
            onPressed: () => ref.invalidate(dashboardControllerProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildDashboardBody(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Failed to load dashboard data: $err', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardBody(BuildContext context, DashboardStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatsGrid(stats),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _buildNavigationButtons(context),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    final currencyFormat = NumberFormat.currency(symbol: '$', decimalDigits: 2);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Seat Occupancy',
          value: '${stats.reservedSeats} / ${stats.totalSeats}',
          icon: Icons.chair,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Available Seats',
          value: stats.availableSeats.toString(),
          icon: Icons.event_available,
          color: Colors.green,
        ),
        _StatCard(
          title: 'Fees Collected (Month)',
          value: currencyFormat.format(stats.totalFeesCollectedThisMonth),
          icon: Icons.account_balance_wallet,
          color: Colors.purple,
        ),
        _StatCard(
          title: 'Pending Fees',
          value: currencyFormat.format(stats.pendingFeesAmount),
          icon: Icons.warning_amber,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'New Students (Month)',
          value: stats.newStudentsThisMonth.toString(),
          icon: Icons.person_add,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.people),
          label: const Text('Manage Students'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentListScreen())),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.grid_on),
          label: const Text('Manage Seats'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SeatManagementScreen())),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Assign Seats'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SeatAssignmentScreen())),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
