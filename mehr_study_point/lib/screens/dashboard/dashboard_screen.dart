import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';
import '../../models/fee_model.dart';
import '../students/add_student_screen.dart';
import '../fees/fee_management_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final stats = ref.watch(dashboardStatsProvider);
    final students = ref.watch(studentsStreamProvider).value ?? [];

    if (userProfile?.role == UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndPromptMonthlyFees(context, ref);
      });
    }

    final recentStudents = students
        .where((s) => s.status == 'Active')
        .toList()
      ..sort((a, b) => b.admissionDate.compareTo(a.admissionDate));
    final displayStudents = recentStudents.take(2).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(dashboardStatsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${userProfile?.name.split(' ').first ?? 'Admin'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C1E),
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, dd MMMM').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: userProfile?.photoUrl != null
                        ? NetworkImage(userProfile!.photoUrl!)
                        : null,
                    backgroundColor: Colors.grey.shade200,
                    child: userProfile?.photoUrl == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Stat Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Active Students',
                      stats.activeStudents.toString(),
                      Icons.people_alt_rounded,
                      const Color(0xFF4CAF50),
                      const Color(0xFFE8F5E9),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Pending Fees',
                      'Rs. ${stats.pendingFees.toInt()}',
                      Icons.account_balance_wallet_rounded,
                      const Color(0xFFEF6C00),
                      const Color(0xFFFFF3E0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Seat Occupancy
              _buildOccupancyCard(context, stats),
              const SizedBox(height: 30),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(
                    context,
                    'Add Student',
                    Icons.person_add_alt_1_rounded,
                    const Color(0xFF2D62ED),
                    true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStudentScreen())),
                  ),
                  _buildQuickAction(
                    context,
                    'Assign Seat',
                    Icons.event_seat_rounded,
                    Colors.blue.shade700,
                    false,
                    onTap: () {}, // Navigate to seat assignment or similar
                  ),
                  _buildQuickAction(
                    context,
                    'Collect Fee',
                    Icons.payments_rounded,
                    Colors.blue.shade700,
                    false,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeeManagementScreen())),
                  ),
                  _buildQuickAction(
                    context,
                    'Reports',
                    Icons.bar_chart_rounded,
                    Colors.blue.shade700,
                    false,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Recent Enrollments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Enrollments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                  TextButton(
                    onPressed: () {}, // Navigate to all students
                    child: const Text('View All', style: TextStyle(color: Color(0xFF2D62ED))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...displayStudents.map((student) => _buildRecentStudentItem(context, student)),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withAlpha((255 * 0.8).round()),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyCard(BuildContext context, DashboardStats stats) {
    final occupied = stats.totalSeats - stats.availableSeats;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seat Occupancy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 65,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: stats.availableSeats.toDouble(),
                        color: const Color(0xFF4CAF50),
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: occupied.toDouble(),
                        color: const Color(0xFFF44336),
                        radius: 20,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${stats.availableSeats}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // In image it seems white or very light
                        ),
                      ),
                      Text(
                        '/${stats.totalSeats}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withAlpha((255 * 0.8).round()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Available (${stats.availableSeats})', const Color(0xFF4CAF50)),
              const SizedBox(width: 24),
              _buildLegendItem('Occupied ($occupied)', const Color(0xFFF44336)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color, bool isPrimary, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: isPrimary ? color : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!isPrimary)
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.05).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1C1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStudentItem(BuildContext context, StudentModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.02).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE3F2FD),
            child: Text(
              student.fullName[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF2196F3),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Seat: ${student.assignedSeatNumber ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('dd MMM').format(student.admissionDate),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
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
