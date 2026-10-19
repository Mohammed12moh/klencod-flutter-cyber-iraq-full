import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/content_provider.dart';
import '../../core/models/learning_path.dart';
import '../../core/models/lesson_progress.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathsAsync = ref.watch(pathsProvider);
    final progressAsync = ref.watch(myProgressProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سايبر العراق'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/ai-tutor'),
          icon: const Icon(Icons.smart_toy_outlined),
          label: const Text('المدرس الذكي'),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pathsProvider);
            ref.invalidate(myProgressProvider);
            ref.invalidate(myProfileProvider);
            ref.invalidate(notificationsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              profileAsync.when(
                data: (profile) => _WelcomeCard(
                  name: profile?['display_name'] as String? ?? '',
                  points: (profile?['points'] as int?) ?? 0,
                  level: profile?['current_level'] as String? ?? 'beginner',
                ),
                loading: () => const _WelcomeCard(name: '', points: 0, level: 'beginner'),
                error: (_, __) => const _WelcomeCard(name: '', points: 0, level: 'beginner'),
              ),
              const SizedBox(height: 20),
              progressAsync.when(
                data: (progress) => _ProgressSummary(progress: progress),
                loading: () => const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Text('المسارات التعليمية',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              pathsAsync.when(
                data: (paths) {
                  if (paths.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('لا توجد مسارات منشورة حالياً.'),
                    );
                  }
                  return Column(
                    children: paths.map((p) => _PathTile(path: p)).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('تعذر تحميل المسارات. اسحب للتحديث.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ),
              const SizedBox(height: 24),
              Text('الإشعارات',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              notificationsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('لا توجد إشعارات حالياً.');
                  }
                  return Column(
                    children: items
                        .map((n) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.notifications_outlined),
                                title: Text(n['title'] as String? ?? ''),
                                subtitle: Text(n['body'] as String? ?? ''),
                              ),
                            ))
                        .toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  final int points;
  final String level;
  const _WelcomeCard({required this.name, required this.points, required this.level});

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
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              child: Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? 'أهلاً بيك' : 'أهلاً بيك، $name',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('المستوى: ${_levelLabel(level)} · $points نقطة',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final List<LessonProgressEntry> progress;
  const _ProgressSummary({required this.progress});

  @override
  Widget build(BuildContext context) {
    final completed = progress.where((p) => p.isCompleted).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.task_alt, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('أكملت $completed درساً حتى الآن',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathTile extends StatelessWidget {
  final LearningPath path;
  const _PathTile({required this.path});

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
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.route_outlined, color: Theme.of(context).colorScheme.primary),
        title: Text(path.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${_levelLabel(path.level)}${path.description != null ? ' · ${path.description}' : ''}'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => context.push('/paths/${path.id}', extra: path.title),
      ),
    );
  }
}
