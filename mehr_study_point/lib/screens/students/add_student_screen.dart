
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
    // Listen for changes in the seat provider to prevent state mismatch
    ref.listen<AsyncValue<List<SeatModel>>>(seatsStreamProvider, (_, next) {
      final seats = next.value ?? [];
      final availableSeatIds = seats.where((s) => s.status == SeatStatus.available).map((s) => s.id).toSet();
      if (_selectedSeat != null && !availableSeatIds.contains(_selectedSeat!.id)) {
        if(mounted) {
          setState(() {
            _selectedSeat = null;
          });
        }
      }
    });

    final isEditing = widget.student != null;
    final seatsAsync = ref.watch(seatsStreamProvider);
    // Ensure uniqueness by converting to a Set and back to a List
    final availableSeats = seatsAsync.value?.where((s) => s.status == SeatStatus.available).toSet().toList() ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[50] : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isEditing ? 'Edit Student' : 'Enroll New Student', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('PERSONAL DETAILS'),
                  _buildCard([
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    _buildTextField(
                      controller: _contactController,
                      label: 'Contact Number',
                      icon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionTitle('FEE CONFIGURATION'),
                  _buildCard([
                    _buildTextField(
                      controller: _monthlyFeeController,
                      label: 'Monthly Fee Rate',
                      icon: Icons.payments_outlined,
                      prefixText: 'Rs. ',
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    if (!isEditing)
                      _buildTextField(
                        controller: _admissionFeeController,
                        label: 'Admission Fee (One-time)',
                        icon: Icons.receipt_long_outlined,
                        prefixText: 'Rs. ',
                        keyboardType: TextInputType.number,
                      ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionTitle('GUARDIAN INFORMATION'),
                  _buildCard([
                    _buildTextField(
                      controller: _guardianNameController,
                      label: 'Guardian Name',
                      icon: Icons.people_outline,
                    ),
                    _buildTextField(
                      controller: _guardianContactController,
                      label: 'Guardian Contact',
                      icon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionTitle('SEAT ASSIGNMENT'),
                  if (!isEditing)
                    _buildCard([
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButtonFormField<SeatModel>(
                          decoration: InputDecoration(
                            labelText: 'Select an available seat',
                            prefixIcon: const Icon(Icons.event_seat_outlined, color: Colors.blue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
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
                      ),
                    ])
                  else
                    _buildCard([
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.event_seat, color: Colors.blue),
                        ),
                        title: const Text('Currently Occupying', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Seat Number: ${widget.student?.assignedSeatNumber ?? 'None'}'),
                      ),
                    ]),

                  const SizedBox(height: 40),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        isEditing ? 'UPDATE STUDENT DETAILS' : 'ENROLL NEW STUDENT',
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueGrey.shade400, size: 22),
          prefixText: prefixText,
          border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue.shade700)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
