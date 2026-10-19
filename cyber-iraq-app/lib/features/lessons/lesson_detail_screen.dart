import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/content_provider.dart';
import '../../core/services/content_service.dart';

class LessonDetailScreen extends ConsumerStatefulWidget {
  final String lessonId;
  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  bool _marking = false;

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonProvider(widget.lessonId));
    final progressAsync = ref.watch(myProgressProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الدرس')),
        body: lessonAsync.when(
          data: (lesson) {
            if (lesson == null) {
              return const Center(child: Text('تعذر العثور على هذا الدرس.'));
            }
            final entry = progressAsync.maybeWhen(
              data: (list) {
                for (final e in list) {
                  if (e.lessonId == lesson.id) return e;
                }
                return null;
              },
              orElse: () => null,
            );
            final isFavorite = entry?.isFavorite ?? false;
            final isCompleted = entry?.isCompleted ?? false;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(lesson.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: Icon(isFavorite ? Icons.star : Icons.star_border,
                            color: Theme.of(context).colorScheme.primary),
                        onPressed: () async {
                          await ref
                              .read(contentServiceProvider)
                              .toggleFavorite(lesson.id, !isFavorite);
                          ref.invalidate(myProgressProvider);
                        },
                      ),
                    ],
                  ),
                  if (lesson.description != null) ...[
                    const SizedBox(height: 8),
                    Text(lesson.description!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  if (lesson.objectives.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('أهداف الدرس', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...lesson.objectives.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 18),
                              const SizedBox(width: 6),
                              Expanded(child: Text(o)),
                            ],
                          ),
                        )),
                  ],
                  if (lesson.videoUrl != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: const Text('فيديو الدرس'),
                        subtitle: Text(lesson.videoUrl!, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  if (lesson.contentMd != null && lesson.contentMd!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    MarkdownBody(data: lesson.contentMd!),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/lessons/${lesson.id}/quiz'),
                    icon: const Icon(Icons.quiz_outlined),
                    label: const Text('ابدأ اختبار الدرس'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: (_marking || isCompleted)
                        ? null
                        : () async {
                            setState(() => _marking = true);
                            await ref.read(contentServiceProvider).markCompleted(lesson.id);
                            ref.invalidate(myProgressProvider);
                            if (mounted) setState(() => _marking = false);
                          },
                    icon: Icon(isCompleted ? Icons.check : Icons.flag_outlined),
                    label: Text(isCompleted
                        ? 'تم إكمال الدرس'
                        : 'تحديد الدرس كمكتمل بدون اختبار'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => const Center(child: Text('تعذر تحميل الدرس.')),
        ),
      ),
    );
  }
}
