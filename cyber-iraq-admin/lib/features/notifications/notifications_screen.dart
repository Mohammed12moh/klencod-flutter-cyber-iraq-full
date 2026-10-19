import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/notifications_admin_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _audienceLabel(String a) {
    switch (a) {
      case 'active':
        return 'النشطون';
      case 'beginner':
        return 'مبتدئ';
      case 'intermediate':
        return 'متوسط';
      case 'advanced':
        return 'متقدم';
      default:
        return 'الجميع';
    }
  }

  void _openCreateDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String audience = 'all';
    bool saving = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إشعار جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyCtrl,
                    decoration: const InputDecoration(labelText: 'المحتوى'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: audience,
                    decoration: const InputDecoration(labelText: 'الجمهور المستهدف'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('الجميع')),
                      DropdownMenuItem(value: 'active', child: Text('النشطون')),
                      DropdownMenuItem(value: 'beginner', child: Text('مبتدئ')),
                      DropdownMenuItem(value: 'intermediate', child: Text('متوسط')),
                      DropdownMenuItem(value: 'advanced', child: Text('متقدم')),
                    ],
                    onChanged: (v) => setState(() => audience = v ?? 'all'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          setState(() => error = 'أدخل عنوان الإشعار');
                          return;
                        }
                        setState(() => saving = true);
                        try {
                          await ref.read(notificationsAdminServiceProvider).create(
                                title: titleCtrl.text.trim(),
                                body: bodyCtrl.text.trim(),
                                audience: audience,
                              );
                          ref.invalidate(notificationsAdminListProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (_) {
                          setState(() {
                            error = 'تعذر الإرسال. حاول مرة أخرى.';
                            saving = false;
                          });
                        }
                      },
                child: const Text('نشر'),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsAdminListProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الإشعارات')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openCreateDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('إشعار جديد'),
        ),
        body: notificationsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('لا توجد إشعارات بعد.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final n = items[i];
                return Card(
                  child: ListTile(
                    title: Text(n['title'] as String? ?? ''),
                    subtitle: Text(
                        '${n['body'] ?? ''}\nالجمهور: ${_audienceLabel(n['audience'] as String? ?? 'all')}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref
                            .read(notificationsAdminServiceProvider)
                            .delete(n['id'] as String);
                        ref.invalidate(notificationsAdminListProvider);
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => const Center(child: Text('تعذر تحميل الإشعارات.')),
        ),
      ),
    );
  }
}
