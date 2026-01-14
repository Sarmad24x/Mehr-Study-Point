import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import '../models/user_model.dart';

// Stream provider for listening to Auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Future provider to get the current user's profile data
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return null;
  
  return await ref.read(authServiceProvider).getUserData(authUser.uid);
});

// Simple provider to check if the user is an admin
final isAdminProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  return userProfile?.role == UserRole.admin;
});
