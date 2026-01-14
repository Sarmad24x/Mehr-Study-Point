import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_providers.dart';
import '../domain/app_user.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: FutureBuilder<List<AppUser>>(
        future: authRepository.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.fullName[0].toUpperCase()),
                ),
                title: Text(user.fullName),
                subtitle: Text('${user.email} • ${user.role.name.toUpperCase()}'),
                trailing: Switch(
                  value: user.isActive,
                  onChanged: (value) async {
                    final updatedUser = AppUser(
                      id: user.id,
                      email: user.email,
                      fullName: user.fullName,
                      role: user.role,
                      isActive: value,
                    );
                    try {
                      await authRepository.updateUser(updatedUser);
                      // In a real app, you'd use a StateNotifier to refresh this list properly
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User ${value ? "activated" : "deactivated"}')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update user: $e')),
                      );
                    }
                  },
                ),
                onTap: () => _showEditUserDialog(context, ref, user),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        child: const Icon(Icons.person_add),
        tooltip: 'Add Employee',
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (context) {
        UserRole selectedRole = user.role;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit ${user.fullName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Change Role:'),
                  DropdownButton<UserRole>(
                    value: selectedRole,
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedRole = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final updatedUser = AppUser(
                      id: user.id,
                      email: user.email,
                      fullName: user.fullName,
                      role: selectedRole,
                      isActive: user.isActive,
                    );
                    await ref.read(authRepositoryProvider).updateUser(updatedUser);
                    Navigator.pop(context);
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: const Text(
          'To add a new employee, they should first sign up in the app. '
          'Once they sign up, the Admin can find them here and assign their role.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}
