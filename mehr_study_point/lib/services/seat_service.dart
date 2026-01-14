import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seat_model.dart';
import 'hive_service.dart';

class SeatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService;

  SeatService(this._hiveService);

  // Stream of seats from Firestore
  Stream<List<SeatModel>> getSeatsStream() {
    return _firestore.collection('seats').orderBy('seatNumber').snapshots().map(
      (snapshot) {
        final seats = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return SeatModel.fromMap(data);
        }).toList();
        
        // Cache to Hive for offline use
        _cacheSeats(seats);
        return seats;
      },
    );
  }

  // Cache seats to Hive
  void _cacheSeats(List<SeatModel> seats) {
    final box = _hiveService.getBox<SeatModel>(HiveService.seatBoxName);
    final map = {for (var seat in seats) seat.id: seat};
    box.putAll(map);
  }

  // Get seats from Hive (Offline)
  List<SeatModel> getCachedSeats() {
    return _hiveService.getBox<SeatModel>(HiveService.seatBoxName).values.toList();
  }

  // Update seat status
  Future<void> updateSeatStatus(String seatId, SeatStatus status, {String? studentId}) async {
    await _firestore.collection('seats').doc(seatId).update({
      'status': status.name,
      'studentId': studentId,
    });
  }

  // Initial setup: Generate 160 seats (Admin only)
  Future<void> generateInitialSeats() async {
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
