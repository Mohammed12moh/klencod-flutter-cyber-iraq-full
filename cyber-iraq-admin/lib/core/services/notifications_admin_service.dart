import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsAdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchAll() async {
    final rows = await _client
        .from('notifications')
        .select()
        .order('publish_at', ascending: false)
        .limit(100);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> create({
    required String title,
    required String body,
    required String audience,
    DateTime? publishAt,
  }) async {
    final uid = _client.auth.currentUser?.id;
    final row = await _client
        .from('notifications')
        .insert({
          'title': title,
          'body': body,
          'audience': audience,
          'publish_at': (publishAt ?? DateTime.now()).toIso8601String(),
          'created_by': uid,
        })
        .select()
        .single();
    if (uid != null) {
      await _client.from('admin_audit_logs').insert({
        'admin_id': uid,
        'action': 'notification.create',
        'target_table': 'notifications',
        'target_id': row['id'] as String,
        'metadata': {'title': title, 'audience': audience},
      });
    }
  }

  Future<void> delete(String id) async {
    final uid = _client.auth.currentUser?.id;
    await _client.from('notifications').delete().eq('id', id);
    if (uid != null) {
      await _client.from('admin_audit_logs').insert({
        'admin_id': uid,
        'action': 'notification.delete',
        'target_table': 'notifications',
        'target_id': id,
      });
    }
  }
}
