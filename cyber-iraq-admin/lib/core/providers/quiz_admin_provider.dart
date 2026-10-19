import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_question.dart';
import '../services/quiz_admin_service.dart';

final quizAdminServiceProvider = Provider<QuizAdminService>((ref) => QuizAdminService());

final quizQuestionsAdminProvider =
    FutureProvider.family<List<QuizQuestion>, String>((ref, lessonId) {
  return ref.watch(quizAdminServiceProvider).fetchQuestions(lessonId);
});
