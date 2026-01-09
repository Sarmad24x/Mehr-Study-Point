import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/audit_log.dart';

class AuditRepository {
  final SupabaseClient _client;
  final String _table = 'audit_logs';

  AuditRepository(this._client);

  Future<void> log(AuditLog log) async {
    try {
      await _client.from(_table).insert(log.toMap());
    } catch (e) {
      // We don't want to crash the app if logging fails, 
      // but we should know about it.
      print('Failed to save audit log: $e');
    }
  }
}
