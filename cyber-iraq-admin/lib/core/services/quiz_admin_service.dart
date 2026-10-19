import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_question.dart';

class QuizAdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<QuizQuestion>> fetchQuestions(String lessonId) async {
    final rows = await _client
        .from('quiz_questions')
        .select()
        .eq('lesson_id', lessonId)
        .order('sort_order');
    return (rows as List).map((r) => QuizQuestion.fromMap(r)).toList();
  }

  Future<void> _audit(String action, {String? id, Map<String, dynamic>? meta}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('admin_audit_logs').insert({
      'admin_id': uid,
      'action': action,
      'target_table': 'quiz_questions',
      'target_id': id,
      'metadata': meta ?? {},
    });
  }

  Future<void> upsertQuestion({
    String? id,
    required String lessonId,
    required String question,
    required String questionType,
    required List<QuizOption> options,
    required String correctOption,
    String? explanation,
    required int sortOrder,
    required bool isPublished,
  }) async {
    final data = {
      if (id != null) 'id': id,
      'lesson_id': lessonId,
      'question': question,
      'question_type': questionType,
      'options': options.map((o) => o.toMap()).toList(),
      'correct_option': correctOption,
      'explanation': explanation,
      'sort_order': sortOrder,
      'is_published': isPublished,
    };
    final result = await _client.from('quiz_questions').upsert(data).select().single();
    await _audit(id == null ? 'quiz_question.create' : 'quiz_question.update',
        id: result['id'] as String);
  }

  Future<void> deleteQuestion(String id) async {
    await _client.from('quiz_questions').delete().eq('id', id);
    await _audit('quiz_question.delete', id: id);
  }
}
