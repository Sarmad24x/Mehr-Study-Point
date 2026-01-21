import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../models/user_model.dart';
import 'audit_logs_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isCreatingUser = false;

  @override
  Widget build(BuildContext context) {
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
      body: _isCreatingUser 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Creating employee account...'),
            ],
          ))
        : SingleChildScrollView(
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
                    'User Management (Employees)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  usersAsync.when(
                    data: (users) {
                      final employees = users.where((u) => u.role == UserRole.employee).toList();
                      if (employees.isEmpty) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No employees found.'),
                        ));
                      }
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
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDeleteUser(context, employee),
                              ),
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
                    onPressed: () => _showAddUserDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Employee'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                const Text(
                  'Local Data Tools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.sync),
                        title: const Text('Force Cloud Sync'),
                        subtitle: const Text('Clears local cache and re-downloads data'),
                        onTap: () async {
                          await ref.read(hiveServiceProvider).clearAll();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared. Refreshing...')));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
    );
  }

  void _showAddUserDialog(BuildContext outerContext) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Employee'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will create a new account for the employee to log in.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController, 
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController, 
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController, 
                decoration: const InputDecoration(labelText: 'Login Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final name = nameController.text.trim();
                
                Navigator.pop(dialogContext);
                setState(() => _isCreatingUser = true);
                
                try {
                  await ref.read(authServiceProvider).registerEmployee(
                    email: email,
                    password: password,
                    name: name,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      const SnackBar(content: Text('Employee account created successfully!'))
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      SnackBar(content: Text('Failed: $e'))
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isCreatingUser = false);
                }
              }
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, UserModel employee) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Employee?'),
        content: Text('Are you sure you want to remove ${employee.name}? They will no longer be able to access the app profile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(authServiceProvider).deleteUserAccount(employee.id);
              if (mounted) {
                Navigator.pop(dialogContext);
              }
            }, 
            child: const Text('Remove', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}
