import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_auth_service.dart';

final adminAuthServiceProvider = Provider<AdminAuthService>((ref) => AdminAuthService());

final adminAuthStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(adminAuthServiceProvider).onAuthStateChange;
});

final isAdminSignedInProvider = Provider<bool>((ref) {
  final auth = ref.watch(adminAuthStateProvider);
  return auth.maybeWhen(
    data: (state) => state.session != null,
    orElse: () => Supabase.instance.client.auth.currentSession != null,
  );
});
