import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/content_admin_provider.dart';
import 'path_edit_sheet.dart';

class PathsListScreen extends ConsumerWidget {
  const PathsListScreen({super.key});

  String _levelLabel(String l) {
    switch (l) {
      case 'intermediate':
        return 'متوسط';
      case 'advanced':
        return 'متقدم';
      default:
        return 'مبتدئ';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathsAsync = ref.watch(allPathsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة المسارات')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showPathEditSheet(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('مسار جديد'),
        ),
        body: pathsAsync.when(
          data: (paths) {
            if (paths.isEmpty) {
              return const Center(child: Text('لا توجد مسارات بعد. أضف أول مسار.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paths.length,
              itemBuilder: (context, i) {
                final p = paths[i];
                return Card(
                  child: ListTile(
                    title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${_levelLabel(p.level)} · ترتيب ${p.sortOrder}'),
                    leading: Icon(
                      p.isPublished ? Icons.visibility : Icons.visibility_off,
                      color: p.isPublished ? Theme.of(context).colorScheme.primary : null,
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu_book_outlined),
                          tooltip: 'إدارة الدروس',
                          onPressed: () => context.push('/paths/${p.id}/lessons', extra: p.title),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => showPathEditSheet(context, ref, existing: p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('تأكيد الحذف'),
                                content: Text('هل تريد حذف "${p.title}" وجميع دروسه؟'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('إلغاء')),
                                  TextButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('حذف')),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await ref.read(contentAdminServiceProvider).deletePath(p.id);
                              ref.invalidate(allPathsProvider);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => const Center(child: Text('تعذر تحميل المسارات.')),
        ),
      ),
    );
  }
}
