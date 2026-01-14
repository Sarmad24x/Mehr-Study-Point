import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/student_model.dart';
import '../models/fee_model.dart';

class ExportService {
  Future<void> exportStudentsToCSV(List<StudentModel> students) async {
    List<List<dynamic>> rows = [];
    
    // Headers
    rows.add([
      "ID", "Full Name", "Contact", "Guardian", "Guardian Contact", 
      "Address", "Admission Date", "Status", "Seat Number"
    ]);

    for (var s in students) {
      rows.add([
        s.id, s.fullName, s.contactNumber, s.guardianName ?? '', 
        s.guardianContact ?? '', s.address, s.admissionDate.toIso8601String(), 
        s.status, s.assignedSeatNumber ?? ''
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    await _shareFile(csvData, 'students_report.csv');
  }

  Future<void> exportFeesToCSV(List<FeeModel> fees) async {
    List<List<dynamic>> rows = [];
    
    // Headers
    rows.add(["ID", "Student ID", "Amount", "Paid Amount", "Due Date", "Paid Date", "Status", "Type"]);

    for (var f in fees) {
      rows.add([
        f.id, f.studentId, f.amount, f.paidAmount, 
        f.dueDate.toIso8601String(), f.paidDate?.toIso8601String() ?? '', 
        f.status.name, f.type
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    await _shareFile(csvData, 'fees_report.csv');
  }

  Future<void> _shareFile(String content, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    
    await Share.shareXFiles([XFile(file.path)], text: 'Exported Report');
  }
}
