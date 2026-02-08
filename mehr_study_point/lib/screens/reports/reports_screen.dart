
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/service_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);
    final exportService = ref.read(exportServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Financial Overview'),
            const SizedBox(height: 16),
            _buildFinancialSummary(stats, theme),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Inventory & Students'),
            const SizedBox(height: 16),
            _buildInventorySummary(stats, theme),

            const SizedBox(height: 32),
            _buildSectionHeader('Export Center'),
            const SizedBox(height: 16),
            _buildExportCard(
              context,
              title: 'Student Directory',
              subtitle: 'Full list of active and archived students',
              icon: Icons.people_alt_rounded,
              onExport: () => exportService.exportStudents(context),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              context,
              title: 'Fee Collection Ledger',
              subtitle: 'All payment records and pending dues',
              icon: Icons.account_balance_wallet_rounded,
              onExport: () => exportService.exportFees(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.1),
    );
  }

  Widget _buildFinancialSummary(DashboardStats stats, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildReportRow('Expected Revenue (Month)', 'Rs. ${stats.totalExpectedThisMonth.toInt()}', Colors.blue),
            const Divider(height: 30),
            _buildReportRow('Collected Amount', 'Rs. ${stats.totalCollectedThisMonth.toInt()}', Colors.green),
            const Divider(height: 30),
            _buildReportRow('Total Outstanding', 'Rs. ${stats.pendingFees.toInt()}', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySummary(DashboardStats stats, ThemeData theme) {
    final occupancyRate = stats.totalSeats == 0 ? "0" : ((stats.totalSeats - stats.availableSeats) / stats.totalSeats * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildReportRow('Total Seat Capacity', '${stats.totalSeats}', Colors.blueGrey),
            const Divider(height: 30),
            _buildReportRow('Active Occupancy', '$occupancyRate%', Colors.orange),
            const Divider(height: 30),
            _buildReportRow('Total Active Students', '${stats.activeStudents}', Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildExportCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onExport,
  }) {
    return ListTile(
      tileColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.1),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.download_rounded, color: Colors.blueGrey),
      onTap: onExport,
    );
  }
}
