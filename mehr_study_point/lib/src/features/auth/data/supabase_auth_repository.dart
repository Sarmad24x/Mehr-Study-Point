import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

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
}
