import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/student_model.dart';
import '../../models/seat_model.dart';
import '../../providers/service_providers.dart';
import '../../providers/seat_provider.dart';
import '../../providers/auth_provider.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianContactController = TextEditingController();
  final _addressController = TextEditingController();
  
  SeatModel? _selectedSeat;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _guardianNameController.dispose();
    _guardianContactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSeat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a seat')),
      );
      return;
    }

    final currentUser = ref.read(userProfileProvider).value;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final student = StudentModel(
        id: const Uuid().v4(),
        fullName: _nameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        guardianName: _guardianNameController.text.trim().isEmpty ? null : _guardianNameController.text.trim(),
        guardianContact: _guardianContactController.text.trim().isEmpty ? null : _guardianContactController.text.trim(),
        address: _addressController.text.trim(),
        admissionDate: DateTime.now(),
        status: 'Active',
        assignedSeatId: _selectedSeat?.id,
        assignedSeatNumber: _selectedSeat?.seatNumber,
      );

      await ref.read(studentServiceProvider).addStudent(student, currentUser);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student enrolled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seatsAsync = ref.watch(seatsStreamProvider);
    final availableSeats = seatsAsync.value?.where((s) => s.status == SeatStatus.available).toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Enroll New Student')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name*', border: OutlineInputBorder()),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(labelText: 'Contact Number*', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _guardianNameController,
                    decoration: const InputDecoration(labelText: 'Guardian Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _guardianContactController,
                    decoration: const InputDecoration(labelText: 'Guardian Contact', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address*', border: OutlineInputBorder()),
                    maxLines: 2,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text('Assign Seat*', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SeatModel>(
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    hint: const Text('Select an available seat'),
                    value: _selectedSeat,
                    items: availableSeats.map((seat) {
                      return DropdownMenuItem(
                        value: seat,
                        child: Text('Seat ${seat.seatNumber}'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedSeat = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveStudent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enroll Student'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
