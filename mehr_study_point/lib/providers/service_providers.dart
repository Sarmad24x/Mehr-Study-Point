
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';
import '../services/seat_service.dart';
import '../services/student_service.dart';
import '../services/fee_service.dart';
import '../services/export_service.dart';
import '../services/audit_service.dart';

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider for HiveService
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

// Provider for AuditService
final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService();
});

// Provider for SeatService
final seatServiceProvider = Provider<SeatService>((ref) {
  return SeatService(
    ref.watch(hiveServiceProvider),
    ref.watch(auditServiceProvider),
  );
});

// Provider for StudentService
final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService(
    ref.watch(hiveServiceProvider),
    ref.watch(auditServiceProvider),
  );
});

// Provider for FeeService
final feeServiceProvider = Provider<FeeService>((ref) {
  return FeeService(
    ref.watch(hiveServiceProvider),
    ref.watch(auditServiceProvider),
  );
});

// Provider for ExportService
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref);
});
