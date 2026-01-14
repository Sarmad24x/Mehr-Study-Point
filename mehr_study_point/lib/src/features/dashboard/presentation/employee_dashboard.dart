import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../seat/presentation/seat_management_screen.dart';
import '../../seat_assignment/presentation/seat_assignment_screen.dart';
import '../../student/presentation/student_list_screen.dart';
import '../domain/dashboard_stats.dart';
import 'dashboard_controller.dart';

class EmployeeDashboard extends ConsumerWidget {
  final DashboardStats stats;

  const EmployeeDashboard({super.key, required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardControllerProvider.future),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOccupancyChart(context, stats),
              const SizedBox(height: 16),
              _buildStatsGrid(stats),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              _buildNavigationButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccupancyChart(BuildContext context, DashboardStats stats) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Seat Occupancy', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.blue.shade600,
                      value: stats.reservedSeats.toDouble(),
                      title: '${((stats.reservedSeats / (stats.totalSeats == 0 ? 1 : stats.totalSeats)) * 100).toStringAsFixed(0)}%',
                      radius: 40,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.green.shade400,
                      value: stats.availableSeats.toDouble(),
                      title: '${((stats.availableSeats / (stats.totalSeats == 0 ? 1 : stats.totalSeats)) * 100).toStringAsFixed(0)}%',
                      radius: 40,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildLegendItem(Colors.blue.shade600, 'Reserved'),
              const SizedBox(width: 24),
              _buildLegendItem(Colors.green.shade400, 'Available'),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(title: 'Total Seats', value: stats.totalSeats.toString(), icon: Icons.chair_outlined, color: Colors.blue),
        _StatCard(title: 'New Students', value: stats.newStudentsThisMonth.toString(), icon: Icons.person_add_outlined, color: Colors.teal),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _MenuButton(icon: Icons.people_outline, label: 'Manage Students', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentListScreen()))),
      const SizedBox(height: 12),
      _MenuButton(icon: Icons.grid_view_outlined, label: 'Manage Seats', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SeatManagementScreen()))),
      const SizedBox(height: 12),
      _MenuButton(icon: Icons.assignment_turned_in_outlined, label: 'Assign Seats', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SeatAssignmentScreen()))),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
    padding: const EdgeInsets.all(16.0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
    ]),
  );
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _MenuButton({required this.icon, required this.label, required this.onPressed});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.blue.shade700, size: 20)),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const Spacer(),
        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
      ]),
    ),
  );
}
