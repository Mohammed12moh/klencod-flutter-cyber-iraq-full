/// Answer-free question shape, as returned by get_published_quiz_questions.
/// correct_option is never sent to the client before grading.
class QuizQuestionOption {
  final String id;
  final String text;
  QuizQuestionOption({required this.id, required this.text});

  factory QuizQuestionOption.fromMap(Map<String, dynamic> m) =>
      QuizQuestionOption(id: m['id'].toString(), text: m['text'].toString());
}

class QuizQuestion {
  final String id;
  final String question;
  final String questionType; // multiple_choice | true_false
  final List<QuizQuestionOption> options;
  final int sortOrder;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.questionType,
    required this.options,
    required this.sortOrder,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
        id: m['id'] as String,
        question: m['question'] as String,
        questionType: m['question_type'] as String? ?? 'multiple_choice',
        options: ((m['options'] as List?) ?? [])
            .map((o) => QuizQuestionOption.fromMap(o as Map<String, dynamic>))
            .toList(),
        sortOrder: (m['sort_order'] as int?) ?? 0,
      );
}
