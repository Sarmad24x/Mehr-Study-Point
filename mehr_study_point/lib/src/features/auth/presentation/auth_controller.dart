import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_providers.dart';
import '../domain/app_user.dart';

/// Provider for the Supabase User object
final authControllerProvider = StreamProvider.autoDispose<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Provider for the custom AppUser profile (contains role, full name, etc.)
final userProfileProvider = FutureProvider.autoDispose<AppUser?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  
  final user = authState.value;
  if (user == null) return null;

  final authRepository = ref.read(authRepositoryProvider);
  return await authRepository.getCurrentUser();
});
