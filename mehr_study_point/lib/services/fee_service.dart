import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_model.dart';
import '../models/audit_log_model.dart';
import '../models/user_model.dart';
import 'hive_service.dart';
import 'audit_service.dart';

class FeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService;
  final AuditService _auditService;

  FeeService(this._hiveService, this._auditService);

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

  Future<void> addFee(FeeModel fee, UserModel currentUser) async {
    await _firestore.collection('fees').doc(fee.id).set(fee.toMap());

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'CREATE',
      entityType: 'Fee',
      entityId: fee.id,
      newValues: fee.toMap(),
      timestamp: DateTime.now(),
    ));
  }

  Future<void> updateFee(FeeModel fee, UserModel currentUser, {Map<String, dynamic>? oldValues}) async {
    await _firestore.collection('fees').doc(fee.id).update(fee.toMap());

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'UPDATE',
      entityType: 'Fee',
      entityId: fee.id,
      oldValues: oldValues,
      newValues: fee.toMap(),
      timestamp: DateTime.now(),
    ));
  }

  Future<void> markAsPaid(String feeId, double amount, UserModel currentUser) async {
    final updateData = {
      'paidAmount': amount,
      'paidDate': DateTime.now().toIso8601String(),
      'status': 'paid',
    };
    
    await _firestore.collection('fees').doc(feeId).update(updateData);

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'UPDATE',
      entityType: 'Fee',
      entityId: feeId,
      newValues: updateData,
      timestamp: DateTime.now(),
    ));
  }
}
