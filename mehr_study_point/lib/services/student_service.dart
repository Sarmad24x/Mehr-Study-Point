import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/audit_log_model.dart';
import '../models/user_model.dart';
import '../models/seat_model.dart';
import 'hive_service.dart';
import 'audit_service.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService;
  final AuditService _auditService;

  StudentService(this._hiveService, this._auditService);

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

  Future<void> addStudent(StudentModel student, UserModel currentUser) async {
    await _firestore.collection('students').doc(student.id).set(student.toMap());
    
    if (student.assignedSeatId != null) {
      await _firestore.collection('seats').doc(student.assignedSeatId).update({
        'status': 'reserved',
        'studentId': student.id,
      });
    }

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'CREATE',
      entityType: 'Student',
      entityId: student.id,
      newValues: student.toMap(),
      timestamp: DateTime.now(),
    ));
  }

  Future<void> updateStudent(StudentModel student, UserModel currentUser, {Map<String, dynamic>? oldValues}) async {
    await _firestore.collection('students').doc(student.id).update(student.toMap());

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'UPDATE',
      entityType: 'Student',
      entityId: student.id,
      oldValues: oldValues,
      newValues: student.toMap(),
      timestamp: DateTime.now(),
    ));
  }

  // MATURE: Mark Student as Left (Archiving)
  Future<void> markStudentAsLeft(StudentModel student, UserModel currentUser) async {
    final batch = _firestore.batch();

    // 1. Update Student Status
    batch.update(_firestore.collection('students').doc(student.id), {
      'status': 'Archived',
      'leaveDate': DateTime.now().toIso8601String(),
      'assignedSeatId': null,
      'assignedSeatNumber': null,
    });

    // 2. Free the Seat
    if (student.assignedSeatId != null) {
      batch.update(_firestore.collection('seats').doc(student.assignedSeatId), {
        'status': SeatStatus.available.name,
        'studentId': null,
      });
    }

    await batch.commit();

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'ARCHIVE',
      entityType: 'Student',
      entityId: student.id,
      oldValues: {'status': student.status, 'seat': student.assignedSeatNumber},
      newValues: {'status': 'Archived', 'leaveDate': DateTime.now().toIso8601String()},
      timestamp: DateTime.now(),
    ));
  }

  Future<void> deleteStudent(String studentId, UserModel currentUser, {String? seatId}) async {
    await _firestore.collection('students').doc(studentId).delete();
    if (seatId != null) {
      await _firestore.collection('seats').doc(seatId).update({
        'status': 'available',
        'studentId': null,
      });
    }

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'DELETE',
      entityType: 'Student',
      entityId: studentId,
      timestamp: DateTime.now(),
    ));
  }
}
