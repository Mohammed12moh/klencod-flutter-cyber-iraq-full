import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audit_log_service.dart';

final auditLogServiceProvider = Provider<AuditLogService>((ref) => AuditLogService());

final auditLogProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(auditLogServiceProvider).fetchRecent();
});
