import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_user.dart';

abstract class AuthRepository {
  /// Signs in the user with the given email and password.
  Future<void> signInWithEmailAndPassword(String email, String password);

  /// Registers a new user with email, password, and full name.
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.employee,
  });

  /// Signs out the current user.
  Future<void> signOut();

  /// Returns a stream of the current authentication state.
  Stream<User?> get authStateChanges;

  /// Fetches the profile data for the currently logged-in user.
  Future<AppUser?> getCurrentUser();

  /// (Admin only) Fetches all users in the system.
  Future<List<AppUser>> getAllUsers();

  /// (Admin only) Updates an existing user's data (e.g., role, status).
  Future<void> updateUser(AppUser user);
}
