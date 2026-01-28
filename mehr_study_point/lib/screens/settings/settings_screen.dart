import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
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
    final themeMode = ref.watch(themeProvider);
    final students = ref.watch(studentsStreamProvider).value ?? [];
    final fees = ref.watch(feesStreamProvider).value ?? [];
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light 
          ? Colors.grey[50] 
          : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isCreatingUser 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profile Header
                _buildProfileHeader(userProfile),
                const SizedBox(height: 32),

                // PROFILE SETTINGS
                _SettingsSection(
                  title: 'PROFILE SETTINGS',
                  children: [
                    _SettingsTile(
                      icon: Icons.lock_outline,
                      iconColor: Colors.blue.shade700,
                      iconBgColor: Colors.blue.shade50,
                      title: 'Account Security',
                      onTap: () => _showAccountSecurityDialog(context, userProfile),
                    ),
                    _SettingsTile(
                      icon: themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                      iconColor: Colors.orange.shade700,
                      iconBgColor: Colors.orange.shade50,
                      title: 'Dark Theme',
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      iconColor: Colors.blue.shade700,
                      iconBgColor: Colors.blue.shade50,
                      title: 'Notifications',
                      trailing: Switch(value: true, onChanged: (v) {}),
                    ),
                  ],
                ),

                // LIBRARY RULES
                _SettingsSection(
                  title: 'LIBRARY RULES',
                  children: [
                    _SettingsTile(
                      icon: Icons.access_time_rounded,
                      iconColor: Colors.blue.shade700,
                      iconBgColor: Colors.blue.shade50,
                      title: 'Operating Hours',
                      subtitle: '${settings['opening_time']} - ${settings['closing_time']}',
                      onTap: userProfile?.role == UserRole.admin 
                        ? () => _showOperatingHoursDialog(context, settings)
                        : null,
                    ),
                    _SettingsTile(
                      icon: Icons.payments_outlined,
                      iconColor: Colors.blue.shade700,
                      iconBgColor: Colors.blue.shade50,
                      title: 'Fine Rates',
                      subtitle: 'Rs ${settings['fine_rate']} per day overdue',
                      trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
                      onTap: userProfile?.role == UserRole.admin 
                        ? () => _showFineRateDialog(context, settings['fine_rate'])
                        : null,
                    ),
                  ],
                ),

                // STAFF MANAGEMENT (Admin only)
                if (userProfile?.role == UserRole.admin)
                _SettingsSection(
                  title: 'STAFF MANAGEMENT',
                  children: [
                    _SettingsTile(
                      icon: Icons.badge_outlined,
                      iconColor: Colors.blue.shade700,
                      iconBgColor: Colors.blue.shade50,
                      title: 'Manage Employees',
                      onTap: () => _showEmployeeManagement(context),
                    ),
                    _SettingsTile(
                      icon: Icons.history_rounded,
                      iconColor: Colors.blue.shade700,
                      iconBgColor: Colors.blue.shade50,
                      title: 'View Audit Logs',
                      subtitle: 'Track system changes',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AuditLogsScreen())),
                    ),
                    _SettingsTile(
                      icon: Icons.file_download_outlined,
                      iconColor: Colors.blue.shade700,
                      iconBgColor: Colors.blue.shade50,
                      title: 'Export Data (CSV)',
                      onTap: () => _showExportOptions(context, students, fees),
                    ),
                  ],
                ),

                // SUPPORT
                _SettingsSection(
                  title: 'SUPPORT',
                  children: [
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: Colors.grey.shade700,
                      iconBgColor: Colors.grey.shade100,
                      title: 'Help Center',
                      trailing: const Icon(Icons.open_in_new, size: 20, color: Colors.grey),
                    ),
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      iconColor: Colors.grey.shade700,
                      iconBgColor: Colors.grey.shade100,
                      title: 'Privacy Policy',
                    ),
                    _SettingsTile(
                      icon: Icons.sync_rounded,
                      iconColor: Colors.grey.shade700,
                      iconBgColor: Colors.grey.shade100,
                      title: 'Clear Local Cache',
                      onTap: () async {
                         await ref.read(hiveServiceProvider).clearAll();
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared. Restart App.')));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                // Log Out Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade100),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Mehr Study Point v1.0.0 (Stable)',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileHeader(UserModel? user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.shade100,
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 60, color: Colors.orange),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  user?.role.name.toUpperCase() ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user?.name ?? 'Loading...',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          user?.role == UserRole.admin ? 'Administrator' : 'Staff Member',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          user?.email ?? '',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      ],
    );
  }

  void _showFineRateDialog(BuildContext context, int currentRate) {
    final controller = TextEditingController(text: currentRate.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Fine Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter daily overdue fine in PKR (Rs):', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'Rs ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newRate = int.tryParse(controller.text);
              if (newRate != null) {
                ref.read(settingsProvider.notifier).updateFineRate(newRate);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showOperatingHoursDialog(BuildContext context, Map<String, dynamic> settings) async {
    TimeOfDay parseTime(String timeStr) {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      if (parts[1] == 'PM' && hour != 12) hour += 12;
      if (parts[1] == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    }

    String formatTime(TimeOfDay time) {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }

    final openingTime = await showTimePicker(
      context: context,
      initialTime: parseTime(settings['opening_time']),
      helpText: 'Select Opening Time',
    );

    if (openingTime != null) {
      if (!mounted) return;
      final closingTime = await showTimePicker(
        context: context,
        initialTime: parseTime(settings['closing_time']),
        helpText: 'Select Closing Time',
      );

      if (closingTime != null) {
        await ref.read(settingsProvider.notifier).updateOperatingHours(
          formatTime(openingTime),
          formatTime(closingTime),
        );
      }
    }
  }

  void _showAccountSecurityDialog(BuildContext context, UserModel? user) {
    final emailController = TextEditingController(text: user?.email);
    final passwordController = TextEditingController();
    final authUser = ref.read(authServiceProvider).currentUser;
    final isVerified = authUser?.emailVerified ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Security', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Email Section
            const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: isVerified 
                  ? const Icon(Icons.verified, color: Colors.green) 
                  : TextButton(
                      onPressed: () async {
                        await ref.read(authServiceProvider).sendEmailVerification();
                        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent!')));
                      }, 
                      child: const Text('Verify')
                    ),
              ),
            ),
            const SizedBox(height: 16),

            // Password Section
            const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter new password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref.read(authServiceProvider).sendPasswordResetEmail(user!.email);
                        if(mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset link sent to email!')));
                        }
                      } catch (e) {
                         if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        if (emailController.text != user?.email) {
                          await ref.read(authServiceProvider).updateEmail(emailController.text.trim());
                        }
                        if (passwordController.text.isNotEmpty) {
                          await ref.read(authServiceProvider).changePassword(passwordController.text.trim());
                        }
                        if(mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account updated successfully!')));
                        }
                      } catch (e) {
                        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showEmployeeManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Consumer(
          builder: (context, ref, child) {
            final usersAsync = ref.watch(usersStreamProvider);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Manage Employees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => _showAddUserDialog(context), icon: const Icon(Icons.add_circle, color: Colors.blue)),
                    ],
                  ),
                ),
                Expanded(
                  child: usersAsync.when(
                    data: (users) {
                      final employees = users.where((u) => u.role == UserRole.employee).toList();
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: employees.length,
                        itemBuilder: (c, i) => ListTile(
                          title: Text(employees[i].name),
                          subtitle: Text(employees[i].email),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDeleteUser(context, employees[i]),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context, dynamic students, dynamic fees) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Export Students (CSV)'),
            onTap: () {
              Navigator.pop(context);
              ref.read(exportServiceProvider).exportStudentsToCSV(students);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Export Fees (CSV)'),
            onTap: () {
              Navigator.pop(context);
              ref.read(exportServiceProvider).exportFeesToCSV(fees);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Existing methods for Adding and Deleting users...
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
              TextFormField(
                controller: nameController, 
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController, 
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController, 
                decoration: const InputDecoration(labelText: 'Login Password'),
                obscureText: true,
                validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 chars' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                setState(() => _isCreatingUser = true);
                try {
                  await ref.read(authServiceProvider).registerEmployee(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    name: nameController.text.trim(),
                  );
                } finally {
                  if (mounted) setState(() => _isCreatingUser = false);
                }
              }
            },
            child: const Text('Create'),
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
        content: Text('Are you sure you want to remove ${employee.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(authServiceProvider).deleteUserAccount(employee.id);
              if (mounted) Navigator.pop(dialogContext);
            }, 
            child: const Text('Remove', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)) : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
    );
  }
}
