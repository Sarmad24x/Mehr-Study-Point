import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';
import '../services/seat_service.dart';

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider for HiveService
final hiveServiceProvider = Provider<HiveService>((ref) {
  final service = HiveService();
  return service;
});

// Provider for SeatService
final seatServiceProvider = Provider<SeatService>((ref) {
  return SeatService(ref.watch(hiveServiceProvider));
});
