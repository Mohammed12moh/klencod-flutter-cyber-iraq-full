class QuizQuestionResult {
  final String questionId;
  final bool correct;
  final String correctOption;
  final String? explanation;

  QuizQuestionResult({
    required this.questionId,
    required this.correct,
    required this.correctOption,
    this.explanation,
  });

  factory QuizQuestionResult.fromMap(Map<String, dynamic> m) => QuizQuestionResult(
        questionId: m['question_id'] as String,
        correct: m['correct'] as bool? ?? false,
        correctOption: m['correct_option']?.toString() ?? '',
        explanation: m['explanation'] as String?,
      );
}

class QuizResult {
  final int score;
  final bool passed;
  final int passScore;
  final List<QuizQuestionResult> results;

  QuizResult({
    required this.score,
    required this.passed,
    required this.passScore,
    required this.results,
  });

  factory QuizResult.fromMap(Map<String, dynamic> m) => QuizResult(
        score: (m['score'] as num).toInt(),
        passed: m['passed'] as bool? ?? false,
        passScore: (m['pass_score'] as num?)?.toInt() ?? 70,
        results: ((m['results'] as List?) ?? [])
            .map((r) => QuizQuestionResult.fromMap(r as Map<String, dynamic>))
            .toList(),
      );
}
