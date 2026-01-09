import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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

  final _phoneMask = MaskTextInputFormatter(
    mask: '####-#######',
    filter: {"#": RegExp(r'[0-9]')},
  );

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
        ref.invalidate(studentListControllerProvider);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student added successfully!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add student: $e'), backgroundColor: Colors.red),
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
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: border,
                ),
                validator: (v) => v!.isEmpty ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactNumberController,
                inputFormatters: [_phoneMask],
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  hintText: '03XX-XXXXXXX',
                  prefixIcon: const Icon(Icons.phone),
                  border: border,
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.length < 12 ? 'Enter valid phone number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: const Icon(Icons.location_on),
                  border: border,
                ),
                validator: (v) => v!.isEmpty ? 'Address is required' : null,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(),
              ),
              TextFormField(
                controller: _guardianNameController,
                decoration: InputDecoration(
                  labelText: 'Guardian Name (Optional)',
                  prefixIcon: const Icon(Icons.supervisor_account),
                  border: border,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _guardianContactController,
                inputFormatters: [_phoneMask],
                decoration: InputDecoration(
                  labelText: 'Guardian Contact (Optional)',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: border,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _addStudent,
                      child: const Text('Save Student', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
