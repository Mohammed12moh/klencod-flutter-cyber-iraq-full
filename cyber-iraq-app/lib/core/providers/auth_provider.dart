import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Emits whenever Supabase's auth state changes (sign in/out, token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).onAuthStateChange;
});

/// Convenience: is anyone currently signed in?
final isSignedInProvider = Provider<bool>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.maybeWhen(
    data: (state) => state.session != null,
    orElse: () => Supabase.instance.client.auth.currentSession != null,
  );
});
