import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import 'hive_service.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService;

  StudentService(this._hiveService);

  // Stream of students from Firestore
  Stream<List<StudentModel>> getStudentsStream() {
    return _firestore.collection('students').orderBy('admissionDate', descending: true).snapshots().map(
      (snapshot) {
        final students = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return StudentModel.fromMap(data);
        }).toList();
        
        _cacheStudents(students);
        return students;
      },
    );
  }

  void _cacheStudents(List<StudentModel> students) {
    final box = _hiveService.getBox<StudentModel>(HiveService.studentBoxName);
    final map = {for (var student in students) student.id: student};
    box.putAll(map);
  }

  Future<void> addStudent(StudentModel student) async {
    await _firestore.collection('students').doc(student.id).set(student.toMap());
    
    // If student has an assigned seat, update that seat status too
    if (student.assignedSeatId != null) {
      await _firestore.collection('seats').doc(student.assignedSeatId).update({
        'status': 'reserved',
        'studentId': student.id,
      });
    }
  }

  Future<void> updateStudent(StudentModel student) async {
    await _firestore.collection('students').doc(student.id).update(student.toMap());
  }

  Future<void> deleteStudent(String studentId, {String? seatId}) async {
    await _firestore.collection('students').doc(studentId).delete();
    if (seatId != null) {
      await _firestore.collection('seats').doc(seatId).update({
        'status': 'available',
        'studentId': null,
      });
    }
  }
}
