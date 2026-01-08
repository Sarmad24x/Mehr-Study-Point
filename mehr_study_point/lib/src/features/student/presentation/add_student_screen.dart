import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/student_providers.dart';
import '../domain/student.dart';
import 'student_list_controller.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianContactController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;

  Future<void> _addStudent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newStudent = Student(
        id: const Uuid().v4(),
        fullName: _fullNameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        guardianName: _guardianNameController.text.trim(),
        guardianContactNumber: _guardianContactController.text.trim(),
        address: _addressController.text.trim(),
        admissionDate: DateTime.now(),
        isActive: true,
      );

      try {
        await ref.read(studentRepositoryProvider).createStudent(newStudent);
        ref.invalidate(studentListControllerProvider); // Refreshes the student list
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add student: $e')),
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
      appBar: AppBar(title: const Text('Add New Student')),
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
                      onPressed: _addStudent,
                      child: const Text('Save Student'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
