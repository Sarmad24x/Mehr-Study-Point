import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  final String _table = 'users';

  SupabaseAuthRepository(this._client);

  @override
  Stream<User?> get authStateChanges => _client.auth.onAuthStateChange.map((state) => state.session?.user);

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client.from(_table).select().eq('id', user.id).single();
      return AppUser.fromMap(response);
    } catch (e) {
      // If the profile doesn't exist yet, we might want to create it or return null
      return null;
    }
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    try {
      final response = await _client.from(_table).select().order('full_name');
      return (response as List).map((item) => AppUser.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  @override
  Future<void> createUser(AppUser user) async {
    // Note: Creating a user in Supabase Auth requires the Admin SDK or a custom edge function.
    // For this example, we're assuming the user is already created in Auth,
    // and we're just adding their profile record.
    try {
      await _client.from(_table).insert(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  @override
  Future<void> updateUser(AppUser user) async {
    try {
      await _client.from(_table).update(user.toMap()).eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }
}
