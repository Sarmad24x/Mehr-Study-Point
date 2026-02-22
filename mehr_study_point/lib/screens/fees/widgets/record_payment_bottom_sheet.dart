
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/fee_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_providers.dart';

class RecordPaymentBottomSheet extends ConsumerStatefulWidget {
  final FeeModel fee;

  const RecordPaymentBottomSheet({super.key, required this.fee});

  @override
  ConsumerState<RecordPaymentBottomSheet> createState() => _RecordPaymentBottomSheetState();
}

class _RecordPaymentBottomSheetState extends ConsumerState<RecordPaymentBottomSheet> {
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  String? _selectedMethod = 'Cash';
  late double _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.fee.amount - widget.fee.paidAmount;
    _amountController = TextEditingController(text: _remaining.toString());
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Record Payment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text('Remaining Balance: Rs. $_remaining',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount Paid',
              prefixText: 'Rs. ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedMethod,
            decoration: InputDecoration(
              labelText: 'Payment Method',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: ['Cash', 'EasyPaisa', 'JazzCash', 'Bank Transfer']
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (val) => setState(() => _selectedMethod = val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final currentUser = ref.read(userProfileProvider).value;
                if (currentUser == null) return;

                final amount = double.tryParse(_amountController.text) ?? 0;
                await ref.read(feeServiceProvider).markAsPaid(
                      fee: widget.fee,
                      newPaymentAmount: amount,
                      currentUser: currentUser,
                      method: _selectedMethod,
                      notes: _notesController.text.trim(),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Confirm Payment',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
