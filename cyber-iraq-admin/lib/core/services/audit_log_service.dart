import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLogService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchRecent({int limit = 100}) async {
    final rows = await _client
        .from('admin_audit_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}
