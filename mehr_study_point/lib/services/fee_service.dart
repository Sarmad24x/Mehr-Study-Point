import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_model.dart';
import '../models/audit_log_model.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import 'hive_service.dart';
import 'audit_service.dart';
import 'package:uuid/uuid.dart';

class FeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService;
  final AuditService _auditService;

  FeeService(this._hiveService, this._auditService);

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

  // UPDATED: Now uses each student's specific monthlyFee
  Future<int> generateMonthlyFees(List<StudentModel> activeStudents, DateTime dueDate, UserModel currentUser) async {
    final batch = _firestore.batch();
    int count = 0;

    for (var student in activeStudents) {
      if (student.status == 'Active') {
        final feeId = const Uuid().v4();
        final fee = FeeModel(
          id: feeId,
          studentId: student.id,
          amount: student.monthlyFee, // Use student's own rate
          paidAmount: 0.0,
          dueDate: dueDate,
          status: FeeStatus.pending,
          type: 'Monthly',
        );
        
        batch.set(_firestore.collection('fees').doc(feeId), fee.toMap());
        count++;
      }
    }

    await batch.commit();

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'BULK_CREATE',
      entityType: 'Fee',
      entityId: 'multiple',
      newValues: {'count': count},
      timestamp: DateTime.now(),
    ));

    return count;
  }

  Future<void> markAsPaid({
    required FeeModel fee, 
    required double newPaymentAmount, 
    required UserModel currentUser,
    String? method,
    String? notes,
  }) async {
    final totalPaidSoFar = fee.paidAmount + newPaymentAmount;
    
    FeeStatus newStatus;
    if (totalPaidSoFar >= fee.amount) {
      newStatus = FeeStatus.paid;
    } else if (totalPaidSoFar > 0) {
      newStatus = FeeStatus.partial;
    } else {
      newStatus = FeeStatus.pending;
    }

    final updateData = {
      'paidAmount': totalPaidSoFar,
      'paidDate': DateTime.now().toIso8601String(),
      'status': newStatus.name,
      'paymentMethod': method,
      'notes': notes,
    };
    
    await _firestore.collection('fees').doc(fee.id).update(updateData);

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'UPDATE_PAYMENT',
      entityType: 'Fee',
      entityId: fee.id,
      oldValues: {'paid': fee.paidAmount, 'status': fee.status.name},
      newValues: updateData,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> deleteFee(String feeId, UserModel currentUser) async {
    await _firestore.collection('fees').doc(feeId).delete();

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'DELETE',
      entityType: 'Fee',
      entityId: feeId,
      timestamp: DateTime.now(),
    ));
  }

  Future<int> deleteMultipleFees(List<String> feeIds, UserModel currentUser) async {
    final batch = _firestore.batch();
    for (var id in feeIds) {
      batch.delete(_firestore.collection('fees').doc(id));
    }
    await batch.commit();

    await _auditService.logAction(AuditLogModel(
      id: '',
      userId: currentUser.id,
      userName: currentUser.name,
      action: 'BULK_DELETE',
      entityType: 'Fee',
      entityId: 'multiple',
      newValues: {'count': feeIds.length},
      timestamp: DateTime.now(),
    ));
    
    return feeIds.length;
  }
}
