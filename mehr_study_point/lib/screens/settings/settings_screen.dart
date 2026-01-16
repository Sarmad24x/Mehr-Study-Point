import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../models/user_model.dart';
import 'audit_logs_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final usersAsync = ref.watch(usersStreamProvider);
    final students = ref.watch(studentsStreamProvider).value ?? [];
    final fees = ref.watch(feesStreamProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(userProfile?.name ?? 'User'),
                subtitle: Text(userProfile?.email ?? ''),
                trailing: Chip(
                  label: Text(userProfile?.role.name.toUpperCase() ?? ''),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (userProfile?.role == UserRole.admin) ...[
              const Text(
                'Admin Tools',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('View Audit Logs'),
                      subtitle: const Text('Track all system changes'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AuditLogsScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.grid_view),
                      title: const Text('Initialize 160 Seats'),
                      onTap: () async {
                        await ref.read(seatServiceProvider).generateInitialSeats();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Export Students (CSV)'),
                      onTap: () => ref.read(exportServiceProvider).exportStudentsToCSV(students),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: const Text('Export Fees (CSV)'),
                      onTap: () => ref.read(exportServiceProvider).exportFeesToCSV(fees),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'User Management',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              usersAsync.when(
                data: (users) {
                  final employees = users.where((u) => u.role == UserRole.employee).toList();
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      return Card(
                        child: ListTile(
                          title: Text(employee.name),
                          subtitle: Text(employee.email),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add New Employee'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Employee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final user = UserModel(
                id: emailController.text,
                email: emailController.text,
                name: nameController.text,
                role: UserRole.employee,
              );
              await ref.read(authServiceProvider).createUserInFirestore(user);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add Profile'),
          ),
        ],
      ),
    );
  }
}
