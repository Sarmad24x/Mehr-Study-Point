import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_user.dart';

abstract class AuthRepository {
  /// Signs in the user with the given email and password.
  Future<void> signInWithEmailAndPassword(String email, String password);

  /// Signs out the current user.
  Future<void> signOut();

  /// Returns a stream of the current authentication state.
  Stream<User?> get authStateChanges;

  /// Fetches the profile data for the currently logged-in user.
  Future<AppUser?> getCurrentUser();

  /// (SuperAdmin only) Fetches all users in the system.
  Future<List<AppUser>> getAllUsers();

  /// (SuperAdmin only) Creates a new user account.
  Future<void> createUser(AppUser user);

  /// (SuperAdmin only) Updates an existing user's data (e.g., role, status).
  Future<void> updateUser(AppUser user);
}
