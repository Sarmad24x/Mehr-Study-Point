import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/service_providers.dart';
import '../../models/user_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final usersAsync = ref.watch(usersStreamProvider);

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
                'User Management (Employees)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              usersAsync.when(
                data: (users) {
                  final employees =
                      users.where((u) => u.role == UserRole.employee).toList();
                  if (employees.isEmpty) {
                    return const Center(child: Text('No employees found.'));
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
                          trailing: const Icon(Icons.edit_outlined),
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
                onPressed: () {
                  // Show Add Employee Dialog
                  _showAddUserDialog(context, ref);
                },
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
    // In a real app, you'd use Firebase Admin SDK or a Cloud Function to create users.
    // For now, we'll just show the requirement.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Employee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Note: Employees must be registered in Firebase first.'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Logic to save user profile to Firestore collection 'users'
              final user = UserModel(
                id: emailController.text, // Temporary ID logic
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
