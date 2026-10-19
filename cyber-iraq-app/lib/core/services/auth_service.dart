import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    final user = res.user;
    if (user != null) {
      // Create the profile row; RLS only allows id = auth.uid().
      await _client.from('profiles').insert({
        'id': user.id,
        'email': email,
        'display_name': displayName,
      });
    }
  }

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() => _client.auth.signOut();
}
