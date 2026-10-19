import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/admin_auth_provider.dart';
import '../../core/providers/stats_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(platformStatsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(adminAuthServiceProvider).signOut(),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => ref.invalidate(platformStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              statsAsync.when(
                data: (s) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(label: 'إجمالي المستخدمين', value: s.totalUsers),
                    _StatCard(label: 'المستخدمون النشطون', value: s.activeUsers),
                    _StatCard(label: 'المسارات', value: s.totalPaths),
                    _StatCard(label: 'الدروس', value: s.totalLessons),
                    _StatCard(label: 'دروس غير منشورة', value: s.unpublishedLessons),
                    _StatCard(label: 'أسئلة الاختبارات', value: s.totalQuizzes),
                    _StatCard(label: 'دروس مكتملة (كل المستخدمين)', value: s.completedLessons),
                  ],
                ),
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, __) => const Text('تعذر تحميل الإحصائيات.'),
              ),
              const SizedBox(height: 24),
              _NavCard(
                icon: Icons.route_outlined,
                title: 'إدارة المسارات والدروس',
                subtitle: 'إضافة وتعديل ونشر المحتوى التعليمي',
                onTap: () => context.push('/paths'),
              ),
              _NavCard(
                icon: Icons.people_outline,
                title: 'إدارة المستخدمين',
                subtitle: 'بحث، تفعيل/تعطيل، منح صلاحية مدير',
                onTap: () => context.push('/users'),
              ),
              _NavCard(
                icon: Icons.notifications_outlined,
                title: 'إدارة الإشعارات',
                subtitle: 'إنشاء إشعار جديد حسب الجمهور المستهدف',
                onTap: () => context.push('/notifications'),
              ),
              _NavCard(
                icon: Icons.smart_toy_outlined,
                title: 'إدارة المدرس الذكي',
                subtitle: 'تفعيل/تعطيل الميزة ومراقبة الاستهلاك',
                onTap: () => context.push('/ai-tutor-settings'),
              ),
              _NavCard(
                icon: Icons.settings_outlined,
                title: 'إعدادات المنصة',
                subtitle: 'اسم التطبيق، الدعم، الروابط، وضع الصيانة',
                onTap: () => context.push('/settings'),
              ),
              _NavCard(
                icon: Icons.history,
                title: 'سجل تدقيق المدير',
                subtitle: 'كل العمليات الإدارية الحساسة',
                onTap: () => context.push('/audit-log'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$value',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
