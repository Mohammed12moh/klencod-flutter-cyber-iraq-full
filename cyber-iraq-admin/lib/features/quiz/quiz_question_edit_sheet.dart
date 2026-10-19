import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/quiz_question.dart';
import '../../core/providers/quiz_admin_provider.dart';

Future<void> showQuizQuestionEditSheet(
  BuildContext context,
  WidgetRef ref, {
  required String lessonId,
  QuizQuestion? existing,
}) {
  final formKey = GlobalKey<FormState>();
  final questionCtrl = TextEditingController(text: existing?.question ?? '');
  final explanationCtrl = TextEditingController(text: existing?.explanation ?? '');
  final sortCtrl = TextEditingController(text: (existing?.sortOrder ?? 0).toString());
  String type = existing?.questionType ?? 'multiple_choice';
  bool published = existing?.isPublished ?? false;
  bool saving = false;
  String? error;

  // For multiple_choice: up to 4 free-text options (a,b,c,d).
  // For true_false: fixed options "صح" / "خطأ".
  List<TextEditingController> mcOptionCtrls = List.generate(4, (i) {
    final opt = (existing != null && existing.questionType == 'multiple_choice' && i < existing.options.length)
        ? existing.options[i].text
        : '';
    return TextEditingController(text: opt);
  });
  String correctOptionId = existing?.correctOption ??
      (type == 'true_false' ? 'true' : 'a');

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        List<QuizOption> buildOptions() {
          if (type == 'true_false') {
            return [
              QuizOption(id: 'true', text: 'صح'),
              QuizOption(id: 'false', text: 'خطأ'),
            ];
          }
          final ids = ['a', 'b', 'c', 'd'];
          final opts = <QuizOption>[];
          for (var i = 0; i < 4; i++) {
            final text = mcOptionCtrls[i].text.trim();
            if (text.isNotEmpty) opts.add(QuizOption(id: ids[i], text: text));
          }
          return opts;
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(existing == null ? 'سؤال جديد' : 'تعديل السؤال',
                        style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: questionCtrl,
                      decoration: const InputDecoration(labelText: 'نص السؤال'),
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'نوع السؤال'),
                      items: const [
                        DropdownMenuItem(value: 'multiple_choice', child: Text('اختيار من متعدد')),
                        DropdownMenuItem(value: 'true_false', child: Text('صح أو خطأ')),
                      ],
                      onChanged: (v) => setState(() {
                        type = v ?? 'multiple_choice';
                        correctOptionId = type == 'true_false' ? 'true' : 'a';
                      }),
                    ),
                    const SizedBox(height: 12),
                    if (type == 'multiple_choice') ...[
                      for (var i = 0; i < 4; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextFormField(
                            controller: mcOptionCtrls[i],
                            decoration: InputDecoration(
                                labelText: 'الخيار ${['أ', 'ب', 'ج', 'د'][i]}'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      DropdownButtonFormField<String>(
                        value: correctOptionId,
                        decoration: const InputDecoration(labelText: 'الإجابة الصحيحة'),
                        items: const [
                          DropdownMenuItem(value: 'a', child: Text('أ')),
                          DropdownMenuItem(value: 'b', child: Text('ب')),
                          DropdownMenuItem(value: 'c', child: Text('ج')),
                          DropdownMenuItem(value: 'd', child: Text('د')),
                        ],
                        onChanged: (v) => setState(() => correctOptionId = v ?? 'a'),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        value: correctOptionId,
                        decoration: const InputDecoration(labelText: 'الإجابة الصحيحة'),
                        items: const [
                          DropdownMenuItem(value: 'true', child: Text('صح')),
                          DropdownMenuItem(value: 'false', child: Text('خطأ')),
                        ],
                        onChanged: (v) => setState(() => correctOptionId = v ?? 'true'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: explanationCtrl,
                      decoration: const InputDecoration(labelText: 'تفسير الإجابة (اختياري)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: sortCtrl,
                      decoration: const InputDecoration(labelText: 'الترتيب'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('منشور للمستخدمين'),
                      value: published,
                      onChanged: (v) => setState(() => published = v),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final opts = buildOptions();
                              if (type == 'multiple_choice' && opts.length < 2) {
                                setState(() => error = 'أدخل خيارين على الأقل');
                                return;
                              }
                              setState(() => saving = true);
                              try {
                                await ref.read(quizAdminServiceProvider).upsertQuestion(
                                      id: existing?.id,
                                      lessonId: lessonId,
                                      question: questionCtrl.text.trim(),
                                      questionType: type,
                                      options: opts,
                                      correctOption: correctOptionId,
                                      explanation: explanationCtrl.text.trim().isEmpty
                                          ? null
                                          : explanationCtrl.text.trim(),
                                      sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                                      isPublished: published,
                                    );
                                ref.invalidate(quizQuestionsAdminProvider(lessonId));
                                if (ctx.mounted) Navigator.of(ctx).pop();
                              } catch (e) {
                                setState(() {
                                  error = 'تعذر الحفظ. تحقق من الصلاحيات والاتصال.';
                                  saving = false;
                                });
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('حفظ'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    },
  );
}
