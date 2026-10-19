import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ai_tutor_admin_provider.dart';

class AiTutorSettingsScreen extends ConsumerWidget {
  const AiTutorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledAsync = ref.watch(aiTutorEnabledProvider);
    final usageAsync = ref.watch(aiTutorUsageProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة المدرس الذكي')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: enabledAsync.when(
                data: (enabled) => SwitchListTile(
                  title: const Text('تفعيل المدرس الذكي'),
                  subtitle: Text(enabled ? 'مفعّل حالياً للمستخدمين' : 'معطّل حالياً'),
                  value: enabled,
                  onChanged: (v) async {
                    await ref.read(aiTutorAdminServiceProvider).setEnabled(v);
                    ref.invalidate(aiTutorEnabledProvider);
                  },
                ),
                loading: () => const ListTile(title: Text('جاري التحميل...')),
                error: (_, __) => const ListTile(title: Text('تعذر تحميل الحالة')),
              ),
            ),
            const SizedBox(height: 16),
            Text('مراقبة الاستهلاك', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            usageAsync.when(
              data: (stats) => Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('${stats['today']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const Text('رسائل اليوم'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('${stats['total']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const Text('الإجمالي'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('تعذر تحميل بيانات الاستهلاك.'),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'الحد اليومي لكل مستخدم (50 رسالة) وحد طول الرسالة (1500 حرف) مضبوطان حالياً '
                  'داخل Edge Function باسم ai-tutor. لا تُعرض أو تُسجَّل أي مفاتيح API هنا.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
