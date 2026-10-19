import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/quiz_admin_provider.dart';
import 'quiz_question_edit_sheet.dart';

class QuizQuestionsListScreen extends ConsumerWidget {
  final String lessonId;
  final String? lessonTitle;
  const QuizQuestionsListScreen({super.key, required this.lessonId, this.lessonTitle});

  String _optionLabel(String id) {
    switch (id) {
      case 'a':
        return 'أ';
      case 'b':
        return 'ب';
      case 'c':
        return 'ج';
      case 'd':
        return 'د';
      case 'true':
        return 'صح';
      case 'false':
        return 'خطأ';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(quizQuestionsAdminProvider(lessonId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('أسئلة ${lessonTitle ?? ''}')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showQuizQuestionEditSheet(context, ref, lessonId: lessonId),
          icon: const Icon(Icons.add),
          label: const Text('سؤال جديد'),
        ),
        body: questionsAsync.when(
          data: (questions) {
            if (questions.isEmpty) {
              return const Center(child: Text('لا توجد أسئلة بعد لهذا الدرس.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, i) {
                final q = questions[i];
                return Card(
                  child: ListTile(
                    title: Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'الإجابة الصحيحة: ${_optionLabel(q.correctOption)} · ترتيب ${q.sortOrder}'),
                    leading: Icon(
                      q.isPublished ? Icons.visibility : Icons.visibility_off,
                      color: q.isPublished ? Theme.of(context).colorScheme.primary : null,
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => showQuizQuestionEditSheet(context, ref,
                              lessonId: lessonId, existing: q),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('تأكيد الحذف'),
                                content: const Text('هل تريد حذف هذا السؤال؟'),
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
                              await ref.read(quizAdminServiceProvider).deleteQuestion(q.id);
                              ref.invalidate(quizQuestionsAdminProvider(lessonId));
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
          error: (e, __) => const Center(child: Text('تعذر تحميل الأسئلة.')),
        ),
      ),
    );
  }
}
