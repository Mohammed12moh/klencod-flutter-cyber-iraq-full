import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/learning_path.dart';
import '../models/lesson.dart';

/// All writes here are additionally gated by RLS (admin-only policies) —
/// this service just gives the UI a convenient surface and writes a
/// matching admin_audit_logs row after each change.
class ContentAdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<LearningPath>> fetchAllPaths() async {
    final rows = await _client.from('learning_paths').select().order('sort_order');
    return (rows as List).map((r) => LearningPath.fromMap(r)).toList();
  }

  Future<List<Lesson>> fetchAllLessons(String pathId) async {
    final rows = await _client
        .from('lessons')
        .select()
        .eq('path_id', pathId)
        .order('sort_order');
    return (rows as List).map((r) => Lesson.fromMap(r)).toList();
  }

  Future<void> _audit(String action, {String? table, String? id, Map<String, dynamic>? meta}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('admin_audit_logs').insert({
      'admin_id': uid,
      'action': action,
      'target_table': table,
      'target_id': id,
      'metadata': meta ?? {},
    });
  }

  Future<void> upsertPath({
    String? id,
    required String title,
    String? description,
    required String level,
    required int sortOrder,
    required bool isPublished,
  }) async {
    final data = {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'level': level,
      'sort_order': sortOrder,
      'is_published': isPublished,
    };
    final result = await _client.from('learning_paths').upsert(data).select().single();
    await _audit(id == null ? 'path.create' : 'path.update',
        table: 'learning_paths', id: result['id'] as String, meta: {'title': title});
  }

  Future<void> deletePath(String id) async {
    await _client.from('learning_paths').delete().eq('id', id);
    await _audit('path.delete', table: 'learning_paths', id: id);
  }

  Future<void> upsertLesson({
    String? id,
    required String pathId,
    required String title,
    String? description,
    required List<String> objectives,
    String? contentMd,
    required String difficulty,
    required int estimatedMinutes,
    required int sortOrder,
    String? videoUrl,
    String? imageUrl,
    required bool isPublished,
    int passScore = 70,
  }) async {
    final data = {
      if (id != null) 'id': id,
      'path_id': pathId,
      'title': title,
      'description': description,
      'objectives': objectives,
      'content_md': contentMd,
      'difficulty': difficulty,
      'estimated_minutes': estimatedMinutes,
      'sort_order': sortOrder,
      'video_url': videoUrl,
      'image_url': imageUrl,
      'is_published': isPublished,
      'pass_score': passScore,
    };
    final result = await _client.from('lessons').upsert(data).select().single();
    await _audit(id == null ? 'lesson.create' : 'lesson.update',
        table: 'lessons', id: result['id'] as String, meta: {'title': title});
  }

  Future<void> deleteLesson(String id) async {
    await _client.from('lessons').delete().eq('id', id);
    await _audit('lesson.delete', table: 'lessons', id: id);
  }

  Future<void> setLessonPublished(String id, bool published) async {
    await _client.from('lessons').update({'is_published': published}).eq('id', id);
    await _audit(published ? 'lesson.publish' : 'lesson.unpublish', table: 'lessons', id: id);
  }

  Future<void> setPathPublished(String id, bool published) async {
    await _client.from('learning_paths').update({'is_published': published}).eq('id', id);
    await _audit(published ? 'path.publish' : 'path.unpublish', table: 'learning_paths', id: id);
  }
}
