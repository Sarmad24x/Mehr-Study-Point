import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, dd MMMM').format(DateTime.now()),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.6),
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
                    backgroundColor: colorScheme.surfaceVariant,
                    child: userProfile?.photoUrl == null
                        ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
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
                      const Color(0xFF4CAF50), // Keep success green
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Pending Fees',
                      'Rs. ${stats.pendingFees.toInt()}',
                      Icons.account_balance_wallet_rounded,
                      const Color(0xFFEF6C00), // Keep warning orange
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Seat Occupancy
              _buildOccupancyCard(context, stats),
              const SizedBox(height: 30),

              // Quick Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(
                    context,
                    'Add Student',
                    Icons.person_add_alt_1_rounded,
                    colorScheme.primary,
                    true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStudentScreen())),
                  ),
                  _buildQuickAction(
                    context,
                    'Assign Seat',
                    Icons.event_seat_rounded,
                    colorScheme.secondary,
                    false,
                    onTap: () {},
                  ),
                  _buildQuickAction(
                    context,
                    'Collect Fee',
                    Icons.payments_rounded,
                    colorScheme.secondary,
                    false,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeeManagementScreen())),
                  ),
                  _buildQuickAction(
                    context,
                    'Reports',
                    Icons.bar_chart_rounded,
                    colorScheme.secondary,
                    false,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildUpcomingRenewals(context, ref),

              // Recent Enrollments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Enrollments',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('View All', style: TextStyle(color: colorScheme.primary)),
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

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: accentColor.withOpacity(0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : HSLColor.fromColor(accentColor).withLightness(0.3).toColor(),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : accentColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyCard(BuildContext context, DashboardStats stats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final occupied = stats.totalSeats - stats.availableSeats;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: theme.colorScheme.outline.withOpacity(0.2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seat Occupancy',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                        value: stats.availableSeats.toDouble(),
                        color: const Color(0xFF4CAF50),
                        radius: 18,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: occupied.toDouble(),
                        color: theme.colorScheme.error,
                        radius: 18,
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
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Available',
                        style: theme.textTheme.bodySmall,
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
              _buildLegendItem(context, 'Available', const Color(0xFF4CAF50)),
              const SizedBox(width: 24),
              _buildLegendItem(context, 'Occupied', theme.colorScheme.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color, bool isPrimary, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: isPrimary ? color : (isDark ? Colors.grey[850] : Colors.white),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (!isPrimary && !isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : color,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingRenewals(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fees = ref.watch(feesStreamProvider).value ?? [];
    final students = ref.watch(studentsStreamProvider).value ?? [];

    if (fees.isEmpty || students.isEmpty) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threeDaysFromNow = today.add(const Duration(days: 4));

    final upcomingFees = fees.where((fee) {
      final dueDate = fee.dueDate;
      return (fee.status == FeeStatus.pending || fee.status == FeeStatus.partial) &&
          !dueDate.isBefore(today) &&
          dueDate.isBefore(threeDaysFromNow);
    }).toList();

    if (upcomingFees.isEmpty) {
      return const SizedBox.shrink();
    }

    upcomingFees.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Renewals',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...upcomingFees.map((fee) {
          final student = students.firstWhereOrNull((s) => s.id == fee.studentId);
          if (student == null) {
            return const SizedBox.shrink(); // Don't build for a deleted student
          }
          return _buildRenewalItem(context, fee, student);
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildRenewalItem(BuildContext context, FeeModel fee, StudentModel student) {
    final theme = Theme.of(context);
    final remaining = fee.amount - fee.paidAmount;
    final isDueToday =
        fee.dueDate.day == DateTime.now().day &&
        fee.dueDate.month == DateTime.now().month &&
        fee.dueDate.year == DateTime.now().year;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: theme.brightness == Brightness.dark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
            child: Text(
              student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.secondary,
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
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Owed: Rs. ${remaining.toInt()}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            isDueToday ? 'Due Today' : 'Due: ${DateFormat('dd MMM').format(fee.dueDate)}',
            style: theme.textTheme.bodySmall?.copyWith(
                color: isDueToday ? theme.colorScheme.error : null,
                fontWeight: isDueToday ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }


  Widget _buildRecentStudentItem(BuildContext context, StudentModel student) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: theme.brightness == Brightness.dark
            ? Border.all(color: theme.dividerColor.withOpacity(0.1))
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(
              student.fullName[0].toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.primary,
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
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Seat: ${student.assignedSeatNumber ?? 'N/A'}' ,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            DateFormat('dd MMM').format(student.admissionDate),
            style: theme.textTheme.bodySmall,
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
      DateFormat('MMMM yyyy').format(f.dueDate) == currentMonthStr);

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

extension ColorBrightness on Color {
  Color darker(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
