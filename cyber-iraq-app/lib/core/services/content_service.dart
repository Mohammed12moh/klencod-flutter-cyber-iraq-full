import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/learning_path.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';

/// All reads here rely on RLS: only published paths/lessons come back for
/// a normal user, so there is no need to filter is_published client-side.
class ContentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<LearningPath>> fetchPaths() async {
    final rows = await _client
        .from('learning_paths')
        .select()
        .order('sort_order', ascending: true);
    return (rows as List).map((r) => LearningPath.fromMap(r)).toList();
  }

  Future<List<Lesson>> fetchLessons(String pathId) async {
    final rows = await _client
        .from('lessons')
        .select()
        .eq('path_id', pathId)
        .order('sort_order', ascending: true);
    return (rows as List).map((r) => Lesson.fromMap(r)).toList();
  }

  Future<Lesson?> fetchLesson(String lessonId) async {
    final row =
        await _client.from('lessons').select().eq('id', lessonId).maybeSingle();
    if (row == null) return null;
    return Lesson.fromMap(row);
  }

  Future<List<LessonProgressEntry>> fetchMyProgress() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client.from('lesson_progress').select().eq('user_id', uid);
    return (rows as List).map((r) => LessonProgressEntry.fromMap(r)).toList();
  }

  Future<void> markCompleted(String lessonId, {num? score}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('lesson_progress').upsert({
      'user_id': uid,
      'lesson_id': lessonId,
      'is_completed': true,
      if (score != null) 'score': score,
      'completed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,lesson_id');
  }

  Future<void> toggleFavorite(String lessonId, bool favorite) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('lesson_progress').upsert({
      'user_id': uid,
      'lesson_id': lessonId,
      'is_favorite': favorite,
    }, onConflict: 'user_id,lesson_id');
  }

  /// Published notifications, newest first, limited for the home feed.
  Future<List<Map<String, dynamic>>> fetchNotifications({int limit = 5}) async {
    final rows = await _client
        .from('notifications')
        .select()
        .order('publish_at', ascending: false)
        .limit(limit);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> fetchMyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return await _client.from('profiles').select().eq('id', uid).maybeSingle();
  }
}
