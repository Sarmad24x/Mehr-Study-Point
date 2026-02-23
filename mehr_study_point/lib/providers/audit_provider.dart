import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import 'auth_provider.dart';
import '../models/audit_log_model.dart';

final auditLogsStreamProvider = StreamProvider.autoDispose<List<AuditLogModel>>((ref) {
  // Restart stream on auth state change
  ref.watch(authStateProvider);
  return ref.watch(auditServiceProvider).getAuditLogsStream();
});
