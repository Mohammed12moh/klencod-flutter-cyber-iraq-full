import 'package:supabase_flutter/supabase_flutter.dart';

/// Non-sensitive platform settings only. Infrastructure secrets (API keys,
/// service-role keys, signing keys) are never stored in app_settings and
/// never exposed through this screen.
class PlatformSettingsService {
  final SupabaseClient _client = Supabase.instance.client;

  static const _keys = [
    'app_name',
    'app_description',
    'support_contact',
    'privacy_policy_url',
    'terms_url',
    'maintenance_mode',
  ];

  Future<Map<String, dynamic>> fetchAll() async {
    final rows = await _client.from('app_settings').select().in_('key', _keys);
    final map = <String, dynamic>{};
    for (final r in (rows as List)) {
      map[r['key'] as String] = r['value'];
    }
    return map;
  }

  Future<void> save(Map<String, dynamic> values) async {
    final uid = _client.auth.currentUser?.id;
    final rows = values.entries
        .map((e) => {
              'key': e.key,
              'value': e.value,
              'updated_by': uid,
              'updated_at': DateTime.now().toIso8601String(),
            })
        .toList();
    await _client.from('app_settings').upsert(rows);
    if (uid != null) {
      await _client.from('admin_audit_logs').insert({
        'admin_id': uid,
        'action': 'settings.update',
        'target_table': 'app_settings',
        'metadata': {'keys': values.keys.toList()},
      });
    }
  }
}
