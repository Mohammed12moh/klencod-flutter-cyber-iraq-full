import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/content_provider.dart';

class PathDetailScreen extends ConsumerWidget {
  final String pathId;
  final String? pathTitle;
  const PathDetailScreen({super.key, required this.pathId, this.pathTitle});

  String _difficultyLabel(String d) {
    switch (d) {
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
    final lessonsAsync = ref.watch(lessonsForPathProvider(pathId));
    final progressAsync = ref.watch(myProgressProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(pathTitle ?? 'الدروس')),
        body: lessonsAsync.when(
          data: (lessons) {
            if (lessons.isEmpty) {
              return const Center(child: Text('لا توجد دروس منشورة بهذا المسار بعد.'));
            }
            final completedIds = progressAsync.maybeWhen(
              data: (p) => p.where((e) => e.isCompleted).map((e) => e.lessonId).toSet(),
              orElse: () => <String>{},
            );
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, i) {
                final lesson = lessons[i];
                final done = completedIds.contains(lesson.id);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: done
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : null,
                      child: Icon(done ? Icons.check : Icons.play_arrow,
                          color: done ? Theme.of(context).colorScheme.primary : null),
                    ),
                    title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${_difficultyLabel(lesson.difficulty)} · ${lesson.estimatedMinutes} دقيقة'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.push('/lessons/${lesson.id}'),
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
