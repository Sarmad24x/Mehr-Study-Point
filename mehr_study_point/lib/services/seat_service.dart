import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seat_model.dart';
import '../models/student_model.dart';
import '../models/audit_log_model.dart';
import '../models/user_model.dart';
import 'hive_service.dart';
import 'audit_service.dart';

class SeatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService;
  final AuditService? _auditService;

  SeatService(this._hiveService, [this._auditService]);

  // Stream of seats from Firestore
  Stream<List<SeatModel>> getSeatsStream() {
    return _firestore.collection('seats').orderBy('seatNumber').snapshots().map(
      (snapshot) {
        final seats = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return SeatModel.fromMap(data);
        }).toList();
        
        _cacheSeats(seats);
        return seats;
      },
    );
  }

  void _cacheSeats(List<SeatModel> seats) {
    final box = _hiveService.getBox<SeatModel>(HiveService.seatBoxName);
    final map = {for (var seat in seats) seat.id: seat};
    box.putAll(map);
  }

  Future<void> updateSeatStatus(String seatId, SeatStatus status, {String? studentId}) async {
    await _firestore.collection('seats').doc(seatId).update({
      'status': status.name,
      'studentId': studentId,
    });
  }

  // SWAP SEAT LOGIC
  Future<void> swapSeat({
    required StudentModel student,
    required SeatModel oldSeat,
    required SeatModel newSeat,
    required UserModel currentUser,
  }) async {
    final batch = _firestore.batch();

    // 1. Mark old seat as Available
    batch.update(_firestore.collection('seats').doc(oldSeat.id), {
      'status': SeatStatus.available.name,
      'studentId': null,
    });

    // 2. Mark new seat as Reserved for this student
    batch.update(_firestore.collection('seats').doc(newSeat.id), {
      'status': SeatStatus.reserved.name,
      'studentId': student.id,
    });

    // 3. Update student record with new seat info
    batch.update(_firestore.collection('students').doc(student.id), {
      'assignedSeatId': newSeat.id,
      'assignedSeatNumber': newSeat.seatNumber,
    });

    await batch.commit();

    // 4. Log the audit trail
    if (_auditService != null) {
      await _auditService!.logAction(AuditLogModel(
        id: '',
        userId: currentUser.id,
        userName: currentUser.name,
        action: 'UPDATE',
        entityType: 'SeatSwap',
        entityId: student.id,
        oldValues: {'seat': oldSeat.seatNumber},
        newValues: {'seat': newSeat.seatNumber},
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> generateInitialSeats() async {
    final query = await _firestore.collection('seats').limit(1).get();
    if (query.docs.isNotEmpty) return; // Don't regenerate if they exist

    final batch = _firestore.batch();
    for (int i = 1; i <= 160; i++) {
      final docRef = _firestore.collection('seats').doc();
      final seat = SeatModel(
        id: docRef.id,
        seatNumber: i.toString(),
        status: SeatStatus.available,
      );
      batch.set(docRef, seat.toMap());
    }
    await batch.commit();
  }
}
