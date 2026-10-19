class QuizOption {
  final String id;
  final String text;
  QuizOption({required this.id, required this.text});

  Map<String, dynamic> toMap() => {'id': id, 'text': text};
  factory QuizOption.fromMap(Map<String, dynamic> m) =>
      QuizOption(id: m['id'].toString(), text: m['text'].toString());
}

class QuizQuestion {
  final String id;
  final String lessonId;
  final String question;
  final String questionType; // multiple_choice | true_false
  final List<QuizOption> options;
  final String correctOption;
  final String? explanation;
  final int sortOrder;
  final bool isPublished;

  QuizQuestion({
    required this.id,
    required this.lessonId,
    required this.question,
    required this.questionType,
    required this.options,
    required this.correctOption,
    this.explanation,
    required this.sortOrder,
    required this.isPublished,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
        id: m['id'] as String,
        lessonId: m['lesson_id'] as String,
        question: m['question'] as String,
        questionType: m['question_type'] as String? ?? 'multiple_choice',
        options: ((m['options'] as List?) ?? [])
            .map((o) => QuizOption.fromMap(o as Map<String, dynamic>))
            .toList(),
        correctOption: m['correct_option']?.toString() ?? '',
        explanation: m['explanation'] as String?,
        sortOrder: (m['sort_order'] as int?) ?? 0,
        isPublished: m['is_published'] as bool? ?? false,
      );
}
