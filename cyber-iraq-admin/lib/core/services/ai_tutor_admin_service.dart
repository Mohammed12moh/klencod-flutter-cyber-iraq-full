import 'package:supabase_flutter/supabase_flutter.dart';

class AiTutorAdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> isEnabled() async {
    final row = await _client
        .from('app_settings')
        .select('value')
        .eq('key', 'ai_tutor_enabled')
        .maybeSingle();
    if (row == null) return true; // default: on
    final v = row['value'];
    if (v is bool) return v;
    return true;
  }

  Future<void> setEnabled(bool enabled) async {
    final uid = _client.auth.currentUser?.id;
    await _client.from('app_settings').upsert({
      'key': 'ai_tutor_enabled',
      'value': enabled,
      'updated_by': uid,
      'updated_at': DateTime.now().toIso8601String(),
    });
    if (uid != null) {
      await _client.from('admin_audit_logs').insert({
        'admin_id': uid,
        'action': enabled ? 'ai_tutor.enable' : 'ai_tutor.disable',
        'target_table': 'app_settings',
        'target_id': 'ai_tutor_enabled',
      });
    }
  }

  /// Counts today's and all-time AI tutor messages (admin can read all rows
  /// per the ai_usage_select_own_or_admin RLS policy).
  Future<Map<String, int>> usageStats() async {
    final since = DateTime.now();
    final startOfDay = DateTime(since.year, since.month, since.day);

    final todayCount = await _client
        .from('ai_usage_logs')
        .select('id')
        .gte('created_at', startOfDay.toIso8601String())
        .count(CountOption.exact);

    final totalCount = await _client.from('ai_usage_logs').select('id').count(CountOption.exact);

    return {
      'today': todayCount.count,
      'total': totalCount.count,
    };
  }
}
