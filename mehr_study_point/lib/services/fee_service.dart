import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_model.dart';
import 'hive_service.dart';

class FeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService;

  FeeService(this._hiveService);

  // Stream of fees
  Stream<List<FeeModel>> getFeesStream() {
    return _firestore.collection('fees').orderBy('dueDate', descending: true).snapshots().map(
      (snapshot) {
        final fees = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return FeeModel.fromMap(data);
        }).toList();
        
        _cacheFees(fees);
        return fees;
      },
    );
  }

  void _cacheFees(List<FeeModel> fees) {
    final box = _hiveService.getBox<FeeModel>(HiveService.feeBoxName);
    final map = {for (var fee in fees) fee.id: fee};
    box.putAll(map);
  }

  Future<void> addFee(FeeModel fee) async {
    await _firestore.collection('fees').doc(fee.id).set(fee.toMap());
  }

  Future<void> updateFee(FeeModel fee) async {
    await _firestore.collection('fees').doc(fee.id).update(fee.toMap());
  }

  Future<void> markAsPaid(String feeId, double amount) async {
    await _firestore.collection('fees').doc(feeId).update({
      'paidAmount': amount,
      'paidDate': DateTime.now().toIso8601String(),
      'status': 'paid',
    });
  }
}
