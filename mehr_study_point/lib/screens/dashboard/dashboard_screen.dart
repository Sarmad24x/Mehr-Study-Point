
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:mehr_study_point/screens/seats/seat_management_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/service_providers.dart';
import '../../models/user_model.dart';
import '../../models/fee_model.dart';
import '../students/add_student_screen.dart';
import '../fees/fee_management_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/stat_card.dart';
import 'widgets/occupancy_card.dart';
import 'widgets/quick_action_button.dart';
import 'widgets/recent_student_item.dart';
import 'widgets/renewal_item.dart';
import '../../services/fee_generation_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final userProfile = ref.watch(userProfileProvider).value;
    final stats = ref.watch(dashboardStatsProvider);
    final students = ref.watch(studentsStreamProvider).value ?? [];
    final fees = ref.watch(feesStreamProvider).value ?? [];

    if (userProfile?.role == UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FeeGenerationService(ref, context).checkAndPromptMonthlyFees();
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
              _buildHeader(context, ref, userProfile),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Active Students',
                      value: stats.activeStudents.toString(),
                      icon: Icons.people_alt_rounded,
                      accentColor: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: StatCard(
                      title: 'Pending Fees',
                      value: 'Rs. ${stats.pendingFees.toInt()}',
                      icon: Icons.account_balance_wallet_rounded,
                      accentColor: const Color(0xFFEF6C00),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OccupancyCard(stats: stats),
              const SizedBox(height: 30),
              _buildQuickActions(context, colorScheme),
              const SizedBox(height: 30),
              _buildUpcomingRenewals(context, theme, fees, students),
              const SizedBox(height: 30),
              _buildRecentEnrollments(context, theme, displayStudents, colorScheme),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, UserModel? userProfile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
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
        PopupMenuButton<String>(
          offset: const Offset(0, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          onSelected: (value) {
            if (value == 'settings') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            } else if (value == 'logout') {
              _showLogoutDialog(context, ref);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: CircleAvatar(
            radius: 25,
            backgroundImage: userProfile?.photoUrl != null
                ? NetworkImage(userProfile!.photoUrl!)
                : null,
            backgroundColor: colorScheme.surfaceVariant,
            child: userProfile?.photoUrl == null
                ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
                : null,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authServiceProvider).signOut();
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionButton(
              label: 'Add Student',
              icon: Icons.person_add_alt_1_rounded,
              color: colorScheme.primary,
              isPrimary: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStudentScreen())),
            ),
            QuickActionButton(
              label: 'Assign Seat',
              icon: Icons.event_seat_rounded,
              color: colorScheme.secondary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SeatManagementScreen())),
            ),
            QuickActionButton(
              label: 'Collect Fee',
              icon: Icons.payments_rounded,
              color: colorScheme.secondary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeeManagementScreen())),
            ),
            QuickActionButton(
              label: 'Reports',
              icon: Icons.bar_chart_rounded,
              color: colorScheme.secondary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingRenewals(
      BuildContext context, ThemeData theme, List<dynamic> fees, List<dynamic> students) {
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
          return RenewalItem(fee: fee, student: student);
        }),
      ],
    );
  }

  Widget _buildRecentEnrollments(
      BuildContext context, ThemeData theme, List<dynamic> displayStudents, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ...displayStudents.map((student) => RecentStudentItem(student: student)),
      ],
    );
  }
}
