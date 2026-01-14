import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/settings_providers.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _admissionFeeController = TextEditingController();
  final _monthlyFeeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      _admissionFeeController.text = settings.defaultAdmissionFee.toString();
      _monthlyFeeController.text = settings.defaultMonthlyFee.toString();
    } catch (e) {
       // Handle error silently or show a message
    }
  }

  Future<void> _saveFees() async {
    setState(() => _isLoading = true);
    try {
      final settings = AppSettings(
        defaultAdmissionFee: double.parse(_admissionFeeController.text),
        defaultMonthlyFee: double.parse(_monthlyFeeController.text),
        lateFeePerDay: 0,
        lateFeeGracePeriod: 0,
      );
      await ref.read(settingsRepositoryProvider).updateSettings(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fee settings updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('System Settings')),
      body: userProfileAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User profile not found.'));
          
          final isAdmin = user.role == UserRole.admin;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isAdmin) ...[
                  _buildSectionHeader('Fee Configuration'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _admissionFeeController,
                    decoration: const InputDecoration(labelText: 'Default Admission Fee', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _monthlyFeeController,
                    decoration: const InputDecoration(labelText: 'Default Monthly Fee', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveFees,
                    child: const Text('Save Fee Settings'),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                  _buildSectionHeader('User Management'),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_add, color: Colors.blue),
                    title: const Text('Manage Administrator Accounts'),
                    subtitle: const Text('Add, edit, or deactivate employees'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to full user management screen
                    },
                  ),
                   const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                ],
                _buildSectionHeader('Seat Configuration'),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.grid_on, color: Colors.blue),
                  title: const Text('Seat Layout Settings'),
                  subtitle: const Text('Manage seat expansion and numbering'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Role: ${user.role.name.toUpperCase()}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
    );
  }
}
