import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/content_admin_provider.dart';
import 'lesson_edit_sheet.dart';

class LessonsListScreen extends ConsumerWidget {
  final String pathId;
  final String? pathTitle;
  const LessonsListScreen({super.key, required this.pathId, this.pathTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(allLessonsForPathProvider(pathId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('دروس ${pathTitle ?? ''}')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showLessonEditSheet(context, ref, pathId: pathId),
          icon: const Icon(Icons.add),
          label: const Text('درس جديد'),
        ),
        body: lessonsAsync.when(
          data: (lessons) {
            if (lessons.isEmpty) {
              return const Center(child: Text('لا توجد دروس بعد. أضف أول درس لهذا المسار.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, i) {
                final l = lessons[i];
                return Card(
                  child: ListTile(
                    title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${l.estimatedMinutes} دقيقة · ترتيب ${l.sortOrder}'),
                    leading: Icon(
                      l.isPublished ? Icons.visibility : Icons.visibility_off,
                      color: l.isPublished ? Theme.of(context).colorScheme.primary : null,
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.quiz_outlined),
                          tooltip: 'إدارة الأسئلة',
                          onPressed: () =>
                              context.push('/lessons/${l.id}/quiz', extra: l.title),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              showLessonEditSheet(context, ref, pathId: pathId, existing: l),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('تأكيد الحذف'),
                                content: Text('هل تريد حذف الدرس "${l.title}"؟'),
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
                              await ref.read(contentAdminServiceProvider).deleteLesson(l.id);
                              ref.invalidate(allLessonsForPathProvider(pathId));
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
          error: (e, __) => const Center(child: Text('تعذر تحميل الدروس.')),
        ),
      ),
    );
  }
}
