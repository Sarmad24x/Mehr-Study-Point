
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
    
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
        
        final admissionFeeAmount = double.tryParse(_admissionFeeController.text) ?? 1000.0;
        await Future.wait([
          ref.read(feeServiceProvider).addFee(FeeModel(
            id: const Uuid().v4(),
            studentId: studentId,
            amount: admissionFeeAmount,
            paidAmount: 0.0,
            dueDate: DateTime.now(),
            status: FeeStatus.pending,
            type: 'Admission',
          ), currentUser),
          ref.read(feeServiceProvider).addFee(FeeModel(
            id: const Uuid().v4(),
            studentId: studentId,
            amount: monthlyFeeAmount,
            paidAmount: 0.0,
            dueDate: DateTime.now(),
            status: FeeStatus.pending,
            type: 'Monthly',
          ), currentUser),
        ]);
      }
      
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Student updated successfully' : 'Student enrolled successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
    
    final List<SeatModel> availableSeats = (seatsAsync.value ?? [])
        .where((s) => s.status == SeatStatus.available)
        .toList();
    
    availableSeats.sort((a, b) {
      final aNum = int.tryParse(a.seatNumber);
      final bNum = int.tryParse(b.seatNumber);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      return a.seatNumber.compareTo(b.seatNumber);
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isEditing ? 'Edit Profile' : 'New Enrollment'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveStudent,
              child: Text(
                'SAVE',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.person, size: 50, color: colorScheme.primary),
                        ),
                        if (!isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: colorScheme.primary,
                              child: const Icon(Icons.add_a_photo, size: 18, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle(context, 'Basic Information', Icons.info_outline),
                  _buildTextField(
                    context: context,
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter student\'s full name',
                    icon: Icons.person_outline,
                    validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context: context,
                    controller: _contactController,
                    label: 'Contact Number',
                    hint: '03xx xxxxxxx',
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v?.isEmpty ?? true ? 'Contact is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context: context,
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Current living address',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (v) => v?.isEmpty ?? true ? 'Address is required' : null,
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Fee Details', Icons.payments_outlined),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          context: context,
                          controller: _monthlyFeeController,
                          label: 'Monthly Fee',
                          prefixText: 'Rs. ',
                          keyboardType: TextInputType.number,
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      if (!isEditing) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            context: context,
                            controller: _admissionFeeController,
                            label: 'Admission',
                            prefixText: 'Rs. ',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Emergency Contact', Icons.emergency_outlined),
                  _buildTextField(
                    context: context,
                    controller: _guardianNameController,
                    label: 'Guardian Name',
                    hint: 'Father / Guardian name',
                    icon: Icons.people_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context: context,
                    controller: _guardianContactController,
                    label: 'Guardian Contact',
                    hint: 'Emergency phone number',
                    icon: Icons.contact_phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Seat Assignment', Icons.event_seat_outlined),
                  if (!isEditing)
                    DropdownButtonFormField<SeatModel>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        prefixIcon: const Icon(Icons.chair_alt_outlined),
                      ),
                      hint: const Text('Choose a seat'),
                      initialValue: _selectedSeat,
                      items: availableSeats.map((seat) {
                        return DropdownMenuItem(
                          value: seat,
                          child: Text('Seat ${seat.seatNumber}'),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedSeat = value),
                      validator: (value) => value == null ? 'Please select a seat' : null,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_seat, color: colorScheme.primary),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Currently Assigned',
                                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary),
                              ),
                              Text(
                                'Seat Number: ${widget.student?.assignedSeatNumber ?? 'None'}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        isEditing ? 'UPDATE PROFILE' : 'ENROLL STUDENT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 22) : null,
        prefixText: prefixText,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
