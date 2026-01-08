import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_providers.dart';
import '../domain/student.dart';
import 'student_detail_screen.dart';
import 'student_list_controller.dart';

class EditStudentScreen extends ConsumerStatefulWidget {
  final Student student;

  const EditStudentScreen({super.key, required this.student});

  @override
  ConsumerState<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends ConsumerState<EditStudentScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _fullNameController;
  late final TextEditingController _contactNumberController;
  late final TextEditingController _guardianNameController;
  late final TextEditingController _guardianContactController;
  late final TextEditingController _addressController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _fullNameController = TextEditingController(text: widget.student.fullName);
    _contactNumberController = TextEditingController(text: widget.student.contactNumber);
    _guardianNameController = TextEditingController(text: widget.student.guardianName);
    _guardianContactController = TextEditingController(text: widget.student.guardianContactNumber);
    _addressController = TextEditingController(text: widget.student.address);
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final updatedStudent = Student(
        id: widget.student.id,
        fullName: _fullNameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        guardianName: _guardianNameController.text.trim(),
        guardianContactNumber: _guardianContactController.text.trim(),
        address: _addressController.text.trim(),
        admissionDate: widget.student.admissionDate,
        isActive: widget.student.isActive,
        assignedSeatId: widget.student.assignedSeatId,
      );

      try {
        await ref.read(studentRepositoryProvider).updateStudent(updatedStudent);
        ref.invalidate(studentListControllerProvider);
        ref.invalidate(studentDetailProvider(widget.student.id));
        if (mounted) {
          Navigator.of(context).pop(); // Go back to detail screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update student: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _guardianNameController.dispose();
    _guardianContactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactNumberController,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _guardianNameController,
                decoration: const InputDecoration(labelText: 'Guardian Name (Optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _guardianContactController,
                decoration: const InputDecoration(labelText: 'Guardian Contact (Optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Save Changes'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
