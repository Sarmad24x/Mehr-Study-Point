
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
    final batch = _firestore.batch();
    
    // 1. Set Student Data
    batch.set(_firestore.collection('students').doc(student.id), student.toMap());
    
    // 2. Update Seat Status if assigned
    if (student.assignedSeatId != null) {
      batch.update(_firestore.collection('seats').doc(student.assignedSeatId), {
        'status': SeatStatus.reserved.name,
        'studentId': student.id,
      });
    }

    await batch.commit();

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
    final batch = _firestore.batch();
    
    // Handle seat changes during update
    if (oldValues != null) {
      final oldSeatId = oldValues['assignedSeatId'];
      final newSeatId = student.assignedSeatId;
      
      if (oldSeatId != newSeatId) {
        // Free old seat
        if (oldSeatId != null) {
          batch.update(_firestore.collection('seats').doc(oldSeatId), {
            'status': SeatStatus.available.name,
            'studentId': null,
          });
        }
        // Reserve new seat
        if (newSeatId != null) {
          batch.update(_firestore.collection('seats').doc(newSeatId), {
            'status': SeatStatus.reserved.name,
            'studentId': student.id,
          });
        }
      }
    }

    batch.update(_firestore.collection('students').doc(student.id), student.toMap());
    await batch.commit();

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

  // Mark Student as Left (Archiving)
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

  Future<void> unassignSeat(StudentModel student, UserModel currentUser) async {
    if (student.assignedSeatId == null) return;

    final batch = _firestore.batch();

    // 1. Update Student
    batch.update(_firestore.collection('students').doc(student.id), {
      'assignedSeatId': null,
      'assignedSeatNumber': null,
    });

    // 2. Free the Seat
    batch.update(_firestore.collection('seats').doc(student.assignedSeatId!), {
      'status': SeatStatus.available.name,
      'studentId': null,
    });

    await batch.commit();

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'UPDATE',
      entityType: 'Student',
      entityId: student.id,
      oldValues: {'seat': student.assignedSeatNumber},
      newValues: {'seat': null},
      timestamp: DateTime.now(),
    ));
  }

  Future<void> deleteStudent(String studentId, UserModel currentUser, {String? seatId}) async {
    final batch = _firestore.batch();
    
    batch.delete(_firestore.collection('students').doc(studentId));
    
    if (seatId != null) {
      batch.update(_firestore.collection('seats').doc(seatId), {
        'status': SeatStatus.available.name,
        'studentId': null,
      });
    }

    await batch.commit();

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
