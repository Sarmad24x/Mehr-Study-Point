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
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.employee,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.name,
        },
      );
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client.from(_table).select().eq('id', user.id).maybeSingle();
    
    if (response == null) {
      return null;
    }
    
    return AppUser.fromMap(response);
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
  Future<void> updateUser(AppUser user) async {
    try {
      await _client.from(_table).update(user.toMap()).eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }
}
