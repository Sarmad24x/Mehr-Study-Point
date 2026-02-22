import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seat_model.dart';
import '../models/student_model.dart';
import '../models/audit_log_model.dart';
import '../models/user_model.dart';
import 'hive_service.dart';
import 'audit_service.dart';
import 'package:uuid/uuid.dart';

class SeatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService;
  final AuditService? _auditService;

  SeatService(this._hiveService, [this._auditService]);

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

  Future<void> updateSeatStatus(String seatId, SeatStatus status, {String? studentId, DateTime? holdExpiresAt}) async {
    await _firestore.collection('seats').doc(seatId).update({
      'status': status.name,
      'studentId': studentId,
      'holdExpiresAt': holdExpiresAt?.toIso8601String(),
    });
  }

  // ADD SEAT Logic
  Future<void> addSeat(String seatNumber, String? zone, UserModel currentUser) async {
    final id = const Uuid().v4();
    final seat = SeatModel(
      id: id,
      seatNumber: seatNumber,
      status: SeatStatus.available,
      zone: zone,
    );
    await _firestore.collection('seats').doc(id).set(seat.toMap());

    if (_auditService != null) {
      await _auditService.logAction(AuditLogModel(
        id: '',
        userId: currentUser.id,
        userName: currentUser.name,
        action: 'CREATE',
        entityType: 'Seat',
        entityId: id,
        newValues: seat.toMap(),
        timestamp: DateTime.now(),
      ));
    }
  }

  // DELETE SEAT Logic
  Future<void> deleteSeat(String seatId, UserModel currentUser) async {
    await _firestore.collection('seats').doc(seatId).delete();

    if (_auditService != null) {
      await _auditService.logAction(AuditLogModel(
        id: '',
        userId: currentUser.id,
        userName: currentUser.name,
        action: 'DELETE',
        entityType: 'Seat',
        entityId: seatId,
        timestamp: DateTime.now(),
      ));
    }
  }

  // BULK UPDATE Logic
  Future<void> bulkUpdateSeats(List<String> seatIds, SeatStatus newStatus, UserModel currentUser) async {
    final batch = _firestore.batch();
    for (var id in seatIds) {
      batch.update(_firestore.collection('seats').doc(id), {
        'status': newStatus.name,
        if (newStatus == SeatStatus.available || newStatus == SeatStatus.maintenance) 'studentId': null,
        if (newStatus == SeatStatus.available || newStatus == SeatStatus.maintenance) 'holdExpiresAt': null,
      });
    }
    await batch.commit();

    if (_auditService != null) {
      await _auditService.logAction(AuditLogModel(
        id: '',
        userId: currentUser.id,
        userName: currentUser.name,
        action: 'BULK_UPDATE',
        entityType: 'Seat',
        entityId: 'multiple',
        newValues: {'count': seatIds.length, 'status': newStatus.name},
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> swapSeat({
    required StudentModel student,
    required SeatModel oldSeat,
    required SeatModel newSeat,
    required UserModel currentUser,
  }) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('seats').doc(oldSeat.id), {
      'status': SeatStatus.available.name,
      'studentId': null,
    });
    batch.update(_firestore.collection('seats').doc(newSeat.id), {
      'status': SeatStatus.reserved.name,
      'studentId': student.id,
    });
    batch.update(_firestore.collection('students').doc(student.id), {
      'assignedSeatId': newSeat.id,
      'assignedSeatNumber': newSeat.seatNumber,
    });
    await batch.commit();

    if (_auditService != null) {
      await _auditService.logAction(AuditLogModel(
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
    if (query.docs.isNotEmpty) return;
    final batch = _firestore.batch();
    for (int i = 1; i <= 160; i++) {
      final docRef = _firestore.collection('seats').doc();
      final seat = SeatModel(id: docRef.id, seatNumber: i.toString(), status: SeatStatus.available);
      batch.set(docRef, seat.toMap());
    }
    await batch.commit();
  }
}
