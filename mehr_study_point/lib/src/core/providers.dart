import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/audit_repository.dart';

///
/// Provider for the Supabase client
///
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

///
/// Provider for the Audit Repository
///
final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuditRepository(client);
});

///
/// Provider for the Connectivity status
///
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});
