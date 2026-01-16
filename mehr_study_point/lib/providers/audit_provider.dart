import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import '../models/audit_log_model.dart';

final auditLogsStreamProvider = StreamProvider<List<AuditLogModel>>((ref) {
  return ref.watch(auditServiceProvider).getAuditLogsStream();
});
