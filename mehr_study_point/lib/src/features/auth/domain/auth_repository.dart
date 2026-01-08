import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  /// Signs in the user with the given email and password.
  Future<void> signInWithEmailAndPassword(String email, String password);

  /// Signs out the current user.
  Future<void> signOut();

  /// Returns a stream of the current authentication state.
  Stream<User?> get authStateChanges;
}
