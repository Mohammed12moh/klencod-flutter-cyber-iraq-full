import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';

class QuizService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetches questions with NO correct_option or explanation — those only
  /// come back from grade-quiz, after the attempt is graded server-side.
  Future<List<QuizQuestion>> fetchQuestions(String lessonId) async {
    final rows = await _client.rpc(
      'get_published_quiz_questions',
      params: {'p_lesson_id': lessonId},
    );
    return (rows as List).map((r) => QuizQuestion.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// Submits answers to the grade-quiz Edge Function. The score is computed
  /// entirely server-side — this app never sends or trusts a client score.
  Future<QuizResult> submit({
    required String lessonId,
    required Map<String, String> answers,
  }) async {
    final res = await _client.functions.invoke(
      'grade-quiz',
      body: {'lesson_id': lessonId, 'answers': answers},
    );
    if (res.status != 200 || res.data == null) {
      throw Exception('quiz_grading_failed');
    }
    return QuizResult.fromMap(res.data as Map<String, dynamic>);
  }
}
