import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import 'admin_dashboard.dart';
import 'dashboard_controller.dart';
import 'employee_dashboard.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardControllerProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('User profile not found.'),
                  SizedBox(height: 16),
                  Text('Please ensure your record exists in the users table.'),
                ],
              ),
            ),
          );
        }

        return statsAsync.when(
          data: (stats) {
            if (user.role == UserRole.admin) {
              return AdminDashboard(stats: stats);
            } else {
              return EmployeeDashboard(stats: stats);
            }
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Failed to load dashboard data: $err', textAlign: TextAlign.center),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}
