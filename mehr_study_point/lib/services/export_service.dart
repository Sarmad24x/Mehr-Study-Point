
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/student_provider.dart';
import '../providers/fee_provider.dart';
import 'package:intl/intl.dart';

class ExportService {
  final Ref ref;

  ExportService(this.ref);

  Future<void> exportStudents(BuildContext context) async {
    final students = ref.read(studentsStreamProvider).value ?? [];
    
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Name", "Contact", "Guardian", "Seat", "Status", "Monthly Fee", "Admission Date"]);

    for (var s in students) {
      rows.add([
        s.id,
        s.fullName,
        s.contactNumber,
        s.guardianName ?? "N/A",
        s.assignedSeatNumber ?? "N/A",
        s.status,
        s.monthlyFee,
        DateFormat('yyyy-MM-dd').format(s.admissionDate),
      ]);
    }

    await _saveAndShare(rows, "Student_Directory", context);
  }

  Future<void> exportFees(BuildContext context) async {
    final fees = ref.read(feesStreamProvider).value ?? [];
    final students = ref.read(studentsStreamProvider).value ?? [];
    
    List<List<dynamic>> rows = [];
    rows.add(["Student Name", "Type", "Amount", "Paid", "Status", "Due Date", "Payment Method"]);

    for (var f in fees) {
      final student = students.firstWhere((s) => s.id == f.studentId, orElse: () => students.first);
      rows.add([
        student.fullName,
        f.type,
        f.amount,
        f.paidAmount,
        f.status.name,
        DateFormat('yyyy-MM-dd').format(f.dueDate),
        f.paymentMethod ?? "N/A",
      ]);
    }

    await _saveAndShare(rows, "Fee_Ledger", context);
  }

  Future<void> _saveAndShare(List<List<dynamic>> rows, String fileName, BuildContext context) async {
    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFileToWrite = "${directory.path}/$fileName.csv";
    File file = File(pathOfTheFileToWrite);
    await file.writeAsString(csvData);
    
    await Share.shareXFiles([XFile(pathOfTheFileToWrite)], text: '$fileName Export');
  }
}
