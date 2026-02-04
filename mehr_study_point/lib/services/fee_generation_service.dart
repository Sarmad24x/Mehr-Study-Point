
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/fee_model.dart';
import '../providers/auth_provider.dart';
import '../providers/fee_provider.dart';
import '../providers/student_provider.dart';
import '../providers/service_providers.dart';

class FeeGenerationService {
  final WidgetRef ref;
  final BuildContext context;

  FeeGenerationService(this.ref, this.context);

  Future<void> checkAndPromptMonthlyFees() async {
    final fees = ref.read(feesStreamProvider).value ?? [];
    final currentMonthStr = DateFormat('MMMM yyyy').format(DateTime.now());

    final alreadyGenerated = fees.any((f) =>
        f.type == 'Monthly' &&
        DateFormat('MMMM yyyy').format(f.dueDate) == currentMonthStr);

    if (!alreadyGenerated && fees.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('New Month: $currentMonthStr'),
          content: const Text(
              'Monthly fees have not been generated yet. Would you like to generate them now for all active students?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Later')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Generate Now'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _generateMonthlyFees();
      }
    }
  }

  Future<void> _generateMonthlyFees() async {
    final currentUser = ref.read(userProfileProvider).value;
    final students = ref.read(studentsStreamProvider).value ?? [];
    
    if (currentUser == null) return;

    int count = 0;
    for (var student in students) {
      if (student.status == 'Active') {
        await ref.read(feeServiceProvider).addFee(
              FeeModel(
                id: DateTime.now().millisecondsSinceEpoch.toString() + student.id,
                studentId: student.id,
                amount: student.monthlyFee,
                paidAmount: 0.0,
                dueDate: DateTime.now().add(const Duration(days: 5)),
                status: FeeStatus.pending,
                type: 'Monthly',
              ),
              currentUser,
            );
        count++;
      }
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully generated $count monthly fees!')));
    }
  }
}
