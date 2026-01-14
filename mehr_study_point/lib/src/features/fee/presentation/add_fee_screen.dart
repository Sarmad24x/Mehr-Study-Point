import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../data/fee_providers.dart';
import '../domain/fee.dart';
import 'fee_list_controller.dart';

class AddFeeScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;

  const AddFeeScreen({super.key, required this.studentId, required this.studentName});

  @override
  ConsumerState<AddFeeScreen> createState() => _AddFeeScreenState();
}

class _AddFeeScreenState extends ConsumerState<AddFeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveFee() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newFee = Fee(
        id: const Uuid().v4(),
        studentId: widget.studentId,
        amount: double.parse(_amountController.text),
        dueDate: _dueDate,
        status: FeeStatus.pending,
      );

      try {
        await ref.read(feeRepositoryProvider).createFee(newFee);
        ref.invalidate(feeListControllerProvider(widget.studentId));
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fee added successfully'), backgroundColor: Colors.green),
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
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Fee for ${widget.studentName}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(DateFormat.yMMMd().format(_dueDate)),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.edit),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      onPressed: _saveFee,
                      child: const Text('Save Fee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
