import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/student_model.dart';
import '../../models/seat_model.dart';
import '../../models/fee_model.dart';
import '../../providers/service_providers.dart';
import '../../providers/seat_provider.dart';
import '../../providers/auth_provider.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  final StudentModel? student;
  const AddStudentScreen({super.key, this.student});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _guardianNameController;
  late final TextEditingController _guardianContactController;
  late final TextEditingController _addressController;
  late final TextEditingController _admissionFeeController;
  late final TextEditingController _monthlyFeeController;
  
  SeatModel? _selectedSeat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.fullName);
    _contactController = TextEditingController(text: widget.student?.contactNumber);
    _guardianNameController = TextEditingController(text: widget.student?.guardianName);
    _guardianContactController = TextEditingController(text: widget.student?.guardianContact);
    _addressController = TextEditingController(text: widget.student?.address);
    _admissionFeeController = TextEditingController(text: '1000');
    _monthlyFeeController = TextEditingController(text: widget.student?.monthlyFee.toString() ?? '2000');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _guardianNameController.dispose();
    _guardianContactController.dispose();
    _addressController.dispose();
    _admissionFeeController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    
    final isEditing = widget.student != null;

    if (!isEditing && _selectedSeat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a seat')),
      );
      return;
    }

    final currentUser = ref.read(userProfileProvider).value;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final studentId = isEditing ? widget.student!.id : const Uuid().v4();
      final monthlyFeeAmount = double.tryParse(_monthlyFeeController.text) ?? 2000.0;

      final updatedStudent = StudentModel(
        id: studentId,
        fullName: _nameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        guardianName: _guardianNameController.text.trim().isEmpty ? null : _guardianNameController.text.trim(),
        guardianContact: _guardianContactController.text.trim().isEmpty ? null : _guardianContactController.text.trim(),
        address: _addressController.text.trim(),
        admissionDate: isEditing ? widget.student!.admissionDate : DateTime.now(),
        status: isEditing ? widget.student!.status : 'Active',
        assignedSeatId: isEditing ? widget.student!.assignedSeatId : _selectedSeat?.id,
        assignedSeatNumber: isEditing ? widget.student!.assignedSeatNumber : _selectedSeat?.seatNumber,
        monthlyFee: monthlyFeeAmount,
      );

      if (isEditing) {
        await ref.read(studentServiceProvider).updateStudent(
          updatedStudent, 
          currentUser,
          oldValues: widget.student!.toMap(),
        );
      } else {
        await ref.read(studentServiceProvider).addStudent(updatedStudent, currentUser);
        
        // 1. Create Admission Fee
        final admissionFeeAmount = double.tryParse(_admissionFeeController.text) ?? 1000.0;
        await ref.read(feeServiceProvider).addFee(FeeModel(
          id: const Uuid().v4(),
          studentId: studentId,
          amount: admissionFeeAmount,
          paidAmount: 0.0,
          dueDate: DateTime.now(),
          status: FeeStatus.pending,
          type: 'Admission',
        ), currentUser);

        // 2. Create First Month's Fee
        await ref.read(feeServiceProvider).addFee(FeeModel(
          id: const Uuid().v4(),
          studentId: studentId,
          amount: monthlyFeeAmount,
          paidAmount: 0.0,
          dueDate: DateTime.now(),
          status: FeeStatus.pending,
          type: 'Monthly',
        ), currentUser);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Student updated successfully' : 'Student enrolled successfully')),
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
    final isEditing = widget.student != null;
    final seatsAsync = ref.watch(seatsStreamProvider);
    final availableSeats = seatsAsync.value?.where((s) => s.status == SeatStatus.available).toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Student' : 'Enroll New Student')),
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
                    controller: _monthlyFeeController,
                    decoration: const InputDecoration(labelText: 'Monthly Fee Rate*', border: OutlineInputBorder(), prefixText: 'Rs. '),
                    keyboardType: TextInputType.number,
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
                  if (!isEditing) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _admissionFeeController,
                      decoration: const InputDecoration(labelText: 'Admission Fee (One-time)', border: OutlineInputBorder(), prefixText: 'Rs. '),
                      keyboardType: TextInputType.number,
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
                  ] else ...[
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.blue.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.event_seat, color: Colors.blue),
                        title: const Text('Current Seat'),
                        subtitle: Text('Seat Number: ${widget.student?.assignedSeatNumber ?? 'None'}'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveStudent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isEditing ? 'Update Details' : 'Enroll Student'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
