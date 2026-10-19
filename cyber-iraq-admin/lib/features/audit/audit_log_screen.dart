import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/audit_log_provider.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سجل تدقيق المدير')),
        body: logsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const Center(child: Text('لا توجد عمليات مسجلة بعد.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, i) {
                final l = logs[i];
                final createdAt = DateTime.tryParse(l['created_at'] as String? ?? '');
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(l['action'] as String? ?? ''),
                    subtitle: Text(
                        '${l['target_table'] ?? ''} · ${l['target_id'] ?? ''}'
                        '${createdAt != null ? '\n${createdAt.toLocal()}' : ''}'),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => const Center(child: Text('تعذر تحميل سجل التدقيق.')),
        ),
      ),
    );
  }
}
