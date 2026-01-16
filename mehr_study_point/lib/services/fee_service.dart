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

  // ADDED: Method to add a single fee
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

  // Generate Fees for all active students for a specific month
  Future<int> generateMonthlyFees(List<StudentModel> activeStudents, double standardAmount, DateTime dueDate, UserModel currentUser) async {
    final batch = _firestore.batch();
    int count = 0;

    for (var student in activeStudents) {
      if (student.status == 'Active') {
        final feeId = const Uuid().v4();
        final fee = FeeModel(
          id: feeId,
          studentId: student.id,
          amount: standardAmount,
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
      newValues: {'count': count, 'amount': standardAmount},
      timestamp: DateTime.now(),
    ));

    return count;
  }

  // Improved markAsPaid with Partial Payment support
  Future<void> markAsPaid(FeeModel fee, double newPaymentAmount, UserModel currentUser) async {
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
}
