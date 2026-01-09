import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/student/domain/student.dart';

class ReportService {
  /// Exports a list of students to a CSV file and shares it.
  static Future<void> exportStudentsToCsv(List<Student> students) async {
    // 1. Define CSV headers
    List<List<dynamic>> rows = [
      [
        'ID',
        'Full Name',
        'Contact',
        'Guardian',
        'Guardian Contact',
        'Address',
        'Admission Date',
        'Active Status',
        'Seat ID'
      ]
    ];

    // 2. Add student data to rows
    for (var student in students) {
      rows.add([
        student.id,
        student.fullName,
        student.contactNumber,
        student.guardianName ?? '',
        student.guardianContactNumber ?? '',
        student.address,
        student.admissionDate.toIso8601String(),
        student.isActive ? 'Active' : 'Inactive',
        student.assignedSeatId ?? 'N/A',
      ]);
    }

    // 3. Convert rows to CSV string
    String csvData = const ListToCsvConverter().convert(rows);

    // 4. Save to temporary file
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/students_report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);

    // 5. Share the file
    await Share.shareXFiles([XFile(file.path)], text: 'Student Report Export');
  }
}
