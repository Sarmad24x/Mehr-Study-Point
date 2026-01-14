import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log_model.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logAction(AuditLogModel log) async {
    await _firestore.collection('audit_logs').add(log.toMap());
  }

  Stream<List<AuditLogModel>> getAuditLogsStream() {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
