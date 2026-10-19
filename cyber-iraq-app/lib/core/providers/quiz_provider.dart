import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_question.dart';
import '../services/quiz_service.dart';

final quizServiceProvider = Provider<QuizService>((ref) => QuizService());

final quizQuestionsProvider =
    FutureProvider.family<List<QuizQuestion>, String>((ref, lessonId) {
  return ref.watch(quizServiceProvider).fetchQuestions(lessonId);
});
