import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/learning_path.dart';
import '../../core/providers/content_admin_provider.dart';

/// Opens as a bottom sheet to create or edit a learning path.
Future<void> showPathEditSheet(BuildContext context, WidgetRef ref, {LearningPath? existing}) {
  final formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final sortCtrl = TextEditingController(text: (existing?.sortOrder ?? 0).toString());
  String level = existing?.level ?? 'beginner';
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
          child: Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(existing == null ? 'إضافة مسار جديد' : 'تعديل المسار',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'عنوان المسار'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'الوصف'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: level,
                    decoration: const InputDecoration(labelText: 'المستوى'),
                    items: const [
                      DropdownMenuItem(value: 'beginner', child: Text('مبتدئ')),
                      DropdownMenuItem(value: 'intermediate', child: Text('متوسط')),
                      DropdownMenuItem(value: 'advanced', child: Text('متقدم')),
                    ],
                    onChanged: (v) => setState(() => level = v ?? 'beginner'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sortCtrl,
                    decoration: const InputDecoration(labelText: 'ترتيب العرض'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
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
                              await ref.read(contentAdminServiceProvider).upsertPath(
                                    id: existing?.id,
                                    title: titleCtrl.text.trim(),
                                    description: descCtrl.text.trim().isEmpty
                                        ? null
                                        : descCtrl.text.trim(),
                                    level: level,
                                    sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                                    isPublished: published,
                                  );
                              ref.invalidate(allPathsProvider);
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
        );
      });
    },
  );
}
