import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserRow {
  final String id;
  final String? displayName;
  final String? email;
  final String currentLevel;
  final int points;
  final bool isActive;
  final DateTime? createdAt;
  final bool isAdmin;

  AdminUserRow({
    required this.id,
    this.displayName,
    this.email,
    required this.currentLevel,
    required this.points,
    required this.isActive,
    this.createdAt,
    required this.isAdmin,
  });
}

class UsersAdminService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Never selects or returns password/auth-secret fields — only
  /// public profile columns plus a computed isAdmin flag.
  Future<List<AdminUserRow>> search(String query) async {
    var builder = _client.from('profiles').select();
    if (query.trim().isNotEmpty) {
      final q = query.trim();
      builder = builder.or('display_name.ilike.%$q%,email.ilike.%$q%');
    }
    final rows = await builder.order('created_at', ascending: false).limit(100);

    final adminRoles = await _client.from('user_roles').select('user_id').eq('role', 'admin');
    final adminIds = (adminRoles as List).map((r) => r['user_id'] as String).toSet();

    return (rows as List).map((r) {
      final m = r as Map<String, dynamic>;
      return AdminUserRow(
        id: m['id'] as String,
        displayName: m['display_name'] as String?,
        email: m['email'] as String?,
        currentLevel: m['current_level'] as String? ?? 'beginner',
        points: (m['points'] as int?) ?? 0,
        isActive: m['is_active'] as bool? ?? true,
        createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at'] as String) : null,
        isAdmin: adminIds.contains(m['id']),
      );
    }).toList();
  }

  Future<void> _audit(String action, String userId, {Map<String, dynamic>? meta}) async {
    final adminId = _client.auth.currentUser?.id;
    if (adminId == null) return;
    await _client.from('admin_audit_logs').insert({
      'admin_id': adminId,
      'action': action,
      'target_table': 'profiles',
      'target_id': userId,
      'metadata': meta ?? {},
    });
  }

  Future<void> setActive(String userId, bool active) async {
    await _client.from('profiles').update({'is_active': active}).eq('id', userId);
    await _audit(active ? 'user.activate' : 'user.deactivate', userId);
  }

  /// Grants the admin role. Writes are still gated server-side by RLS
  /// (roles_admin_only_write), so even if this UI is modified, only an
  /// existing admin's session can actually make the change.
  Future<void> grantAdmin(String userId) async {
    final adminId = _client.auth.currentUser?.id;
    await _client.from('user_roles').upsert(
      {'user_id': userId, 'role': 'admin', 'granted_by': adminId},
      onConflict: 'user_id,role',
    );
    await _audit('user.role_grant', userId, meta: {'role': 'admin'});
  }

  Future<void> revokeAdmin(String userId) async {
    await _client.from('user_roles').delete().eq('user_id', userId).eq('role', 'admin');
    await _audit('user.role_revoke', userId, meta: {'role': 'admin'});
  }
}
