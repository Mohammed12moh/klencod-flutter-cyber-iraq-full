import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformStats {
  final int totalUsers;
  final int activeUsers;
  final int totalPaths;
  final int totalLessons;
  final int unpublishedLessons;
  final int totalQuizzes;
  final int completedLessons;

  PlatformStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalPaths,
    required this.totalLessons,
    required this.unpublishedLessons,
    required this.totalQuizzes,
    required this.completedLessons,
  });
}

/// Every number here comes from a live count query against the real
/// tables — none of it is hardcoded or simulated.
class StatsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<PlatformStats> fetch() async {
    final totalUsers = await _client.from('profiles').select('id').count(CountOption.exact);
    final activeUsers = await _client
        .from('profiles')
        .select('id')
        .eq('is_active', true)
        .count(CountOption.exact);
    final totalPaths = await _client.from('learning_paths').select('id').count(CountOption.exact);
    final totalLessons = await _client.from('lessons').select('id').count(CountOption.exact);
    final unpublishedLessons = await _client
        .from('lessons')
        .select('id')
        .eq('is_published', false)
        .count(CountOption.exact);
    final totalQuizzes =
        await _client.from('quiz_questions').select('id').count(CountOption.exact);
    final completedLessons = await _client
        .from('lesson_progress')
        .select('id')
        .eq('is_completed', true)
        .count(CountOption.exact);

    return PlatformStats(
      totalUsers: totalUsers.count,
      activeUsers: activeUsers.count,
      totalPaths: totalPaths.count,
      totalLessons: totalLessons.count,
      unpublishedLessons: unpublishedLessons.count,
      totalQuizzes: totalQuizzes.count,
      completedLessons: completedLessons.count,
    );
  }
}
