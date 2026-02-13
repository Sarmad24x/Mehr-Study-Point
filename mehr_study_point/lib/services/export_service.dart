
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/student_provider.dart';
import '../providers/fee_provider.dart';
import 'package:intl/intl.dart';

class ExportService {
  final Ref ref;

  ExportService(this.ref);

  Future<void> exportStudents(BuildContext context) async {
    final students = ref.read(studentsStreamProvider).value ?? [];
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text("Mehr Study Point - Student Directory",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ["Name", "Contact", "Guardian", "Seat", "Status", "Admission"],
              data: students.map((s) => [
                s.fullName,
                s.contactNumber,
                s.guardianName ?? "N/A",
                s.assignedSeatNumber ?? "N/A",
                s.status,
                DateFormat('dd-MM-yy').format(s.admissionDate),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    await _saveAndShare(pdf, "Student_Directory", context);
  }

  Future<void> exportFees(BuildContext context) async {
    final fees = ref.read(feesStreamProvider).value ?? [];
    final students = ref.read(studentsStreamProvider).value ?? [];
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text("Mehr Study Point - Fee Ledger",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ["Student Name", "Type", "Amount", "Paid", "Status", "Due Date"],
              data: fees.map((f) {
                final student = students.firstWhere((s) => s.id == f.studentId, orElse: () => students.first);
                return [
                  student.fullName,
                  f.type,
                  f.amount.toInt().toString(),
                  f.paidAmount.toInt().toString(),
                  f.status.name.toUpperCase(),
                  DateFormat('dd-MM-yy').format(f.dueDate),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    await _saveAndShare(pdf, "Fee_Ledger", context);
  }

  Future<void> _saveAndShare(pw.Document pdf, String fileName, BuildContext context) async {
    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final pathOfTheFileToWrite = "${directory.path}/$fileName.pdf";
    File file = File(pathOfTheFileToWrite);
    await file.writeAsBytes(bytes);
    
    await Share.shareXFiles([XFile(pathOfTheFileToWrite)], text: '$fileName Export');
  }
}
