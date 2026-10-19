import 'package:supabase_flutter/supabase_flutter.dart';

class NotAdminException implements Exception {}

class AdminAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  /// Accepts either a real email, or a bare dev username like "kali" which
  /// is mapped to the dev-only email below. The dev account must exist in
  /// Supabase Auth and be granted the 'admin' role manually (see schema.sql
  /// bootstrap_first_admin) — this mapping does NOT grant privilege itself.
  String _resolveEmail(String usernameOrEmail) {
    final v = usernameOrEmail.trim();
    if (v.contains('@')) return v;
    return '$v@admin.cyberiraq.local'; // dev-only convention
  }

  /// Signs in, then checks the server-side `user_roles` table (never a
  /// client-trusted claim) before letting the caller treat the user as an
  /// admin. Signs the user back out if the role check fails.
  Future<void> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    final email = _resolveEmail(usernameOrEmail);
    await _client.auth.signInWithPassword(email: email, password: password);

    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw NotAdminException();

    final isAdmin = await _client.rpc('is_admin', params: {'uid': uid});
    if (isAdmin != true) {
      await _client.auth.signOut();
      throw NotAdminException();
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}
