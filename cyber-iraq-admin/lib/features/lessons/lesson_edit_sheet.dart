import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/lesson.dart';
import '../../core/providers/content_admin_provider.dart';

Future<void> showLessonEditSheet(
  BuildContext context,
  WidgetRef ref, {
  required String pathId,
  Lesson? existing,
}) {
  final formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final objectivesCtrl =
      TextEditingController(text: existing?.objectives.join('\n') ?? '');
  final contentCtrl = TextEditingController(text: existing?.contentMd ?? '');
  final videoCtrl = TextEditingController(text: existing?.videoUrl ?? '');
  final imageCtrl = TextEditingController(text: existing?.imageUrl ?? '');
  final minutesCtrl =
      TextEditingController(text: (existing?.estimatedMinutes ?? 15).toString());
  final sortCtrl = TextEditingController(text: (existing?.sortOrder ?? 0).toString());
  final passScoreCtrl = TextEditingController(text: (existing?.passScore ?? 70).toString());
  String difficulty = existing?.difficulty ?? 'beginner';
  bool published = existing?.isPublished ?? false;
  bool saving = false;
  String? error;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollCtrl) => Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    Text(existing == null ? 'إضافة درس جديد' : 'تعديل الدرس',
                        style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'عنوان الدرس'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'وصف مختصر'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: objectivesCtrl,
                      decoration:
                          const InputDecoration(labelText: 'أهداف الدرس (سطر لكل هدف)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contentCtrl,
                      decoration: const InputDecoration(labelText: 'محتوى الدرس (Markdown)'),
                      maxLines: 8,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: videoCtrl,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(labelText: 'رابط الفيديو (اختياري)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imageCtrl,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(labelText: 'رابط الصورة (اختياري)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: difficulty,
                      decoration: const InputDecoration(labelText: 'مستوى الصعوبة'),
                      items: const [
                        DropdownMenuItem(value: 'beginner', child: Text('مبتدئ')),
                        DropdownMenuItem(value: 'intermediate', child: Text('متوسط')),
                        DropdownMenuItem(value: 'advanced', child: Text('متقدم')),
                      ],
                      onChanged: (v) => setState(() => difficulty = v ?? 'beginner'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: minutesCtrl,
                            decoration: const InputDecoration(labelText: 'المدة (دقيقة)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: sortCtrl,
                            decoration: const InputDecoration(labelText: 'الترتيب'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passScoreCtrl,
                      decoration: const InputDecoration(labelText: 'درجة النجاح بالاختبار (%)'),
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
                              setState(() => saving = true);
                              try {
                                final objectives = objectivesCtrl.text
                                    .split('\n')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();
                                await ref.read(contentAdminServiceProvider).upsertLesson(
                                      id: existing?.id,
                                      pathId: pathId,
                                      title: titleCtrl.text.trim(),
                                      description: descCtrl.text.trim().isEmpty
                                          ? null
                                          : descCtrl.text.trim(),
                                      objectives: objectives,
                                      contentMd: contentCtrl.text.trim().isEmpty
                                          ? null
                                          : contentCtrl.text.trim(),
                                      difficulty: difficulty,
                                      estimatedMinutes: int.tryParse(minutesCtrl.text) ?? 15,
                                      sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                                      videoUrl: videoCtrl.text.trim().isEmpty
                                          ? null
                                          : videoCtrl.text.trim(),
                                      imageUrl: imageCtrl.text.trim().isEmpty
                                          ? null
                                          : imageCtrl.text.trim(),
                                      isPublished: published,
                                      passScore: int.tryParse(passScoreCtrl.text) ?? 70,
                                    );
                                ref.invalidate(allLessonsForPathProvider(pathId));
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
