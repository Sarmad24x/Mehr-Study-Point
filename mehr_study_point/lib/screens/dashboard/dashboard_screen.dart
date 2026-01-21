import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/seat_provider.dart';
import '../../models/user_model.dart';
import '../../models/seat_model.dart';
import '../../models/student_model.dart';
import '../../models/fee_model.dart';
import '../students/student_details_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final stats = ref.watch(dashboardStatsProvider);
    final students = ref.watch(studentsStreamProvider).value ?? [];
    final seats = ref.watch(seatsStreamProvider).value ?? [];

    if (userProfile?.role == UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndPromptMonthlyFees(context, ref);
      });
    }

    // Get 3 most recent active students
    final recentStudents = students
        .where((s) => s.status == 'Active')
        .toList()
      ..sort((a, b) => b.admissionDate.compareTo(a.admissionDate));
    final displayStudents = recentStudents.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mehr Study Point'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(dashboardStatsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${userProfile?.name ?? 'User'}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        DateFormat('EEEE, dd MMMM').format(DateTime.now()),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Stat Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(context, 'Active Students', stats.activeStudents.toString(), Icons.people, Colors.green),
                  _buildStatCard(context, 'Pending Fees', 'Rs. ${stats.pendingFees.toInt()}', Icons.account_balance_wallet, Colors.orange),
                ],
              ),
              const SizedBox(height: 24),

              // Visual Charts Row
              _buildChartCard(
                context, 
                title: 'Seat Occupancy',
                chart: _buildOccupancyPie(stats),
              ),
              const SizedBox(height: 24),

              // Recent Students Section (Using StudentModel)
              if (displayStudents.isNotEmpty) ...[
                Text(
                  'Recent Enrollments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...displayStudents.map((student) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(student.fullName[0].toUpperCase()),
                    ),
                    title: Text(student.fullName),
                    subtitle: Text('Seat: ${student.assignedSeatNumber ?? 'N/A'}'),
                    trailing: Text(DateFormat('dd MMM').format(student.admissionDate)),
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => StudentDetailsScreen(student: student)),
                    ),
                  ),
                )),
                const SizedBox(height: 24),
              ],

              // Zone Breakdown (Using SeatModel)
              Text(
                'Zone Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildZoneSummary(seats),

              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneSummary(List<SeatModel> seats) {
    if (seats.isEmpty) return const Card(child: ListTile(title: Text('No seats initialized')));
    
    final zones = seats.map((s) => s.zone ?? 'General').toSet().toList();
    zones.sort();

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: zones.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final zone = zones[index];
          final zoneSeats = seats.where((s) => (s.zone ?? 'General') == zone).toList();
          final occupied = zoneSeats.where((s) => s.status == SeatStatus.reserved).length;
          
          return ListTile(
            title: Text(zone),
            subtitle: Text('Occupancy: $occupied / ${zoneSeats.length}'),
            trailing: SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: zoneSeats.isEmpty ? 0 : occupied / zoneSeats.length,
                backgroundColor: Colors.grey.shade200,
                color: (occupied / zoneSeats.length) > 0.8 ? Colors.red : Colors.blue,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, {required String title, required Widget chart}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.blue.shade50.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyPie(DashboardStats stats) {
    final reserved = stats.totalSeats - stats.availableSeats;
    if (stats.totalSeats == 0) return const Center(child: Text('No data'));

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: stats.availableSeats.toDouble(),
            title: '${stats.availableSeats}',
            color: Colors.green,
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            value: reserved.toDouble(),
            title: '$reserved',
            color: Colors.red,
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Future<void> _checkAndPromptMonthlyFees(BuildContext context, WidgetRef ref) async {
    final fees = ref.read(feesStreamProvider).value ?? [];
    final currentMonthStr = DateFormat('MMMM yyyy').format(DateTime.now());
    
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
}
