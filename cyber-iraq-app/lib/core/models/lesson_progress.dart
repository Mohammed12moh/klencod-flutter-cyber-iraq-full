class LessonProgressEntry {
  final String lessonId;
  final bool isCompleted;
  final bool isFavorite;
  final num? score;

  LessonProgressEntry({
    required this.lessonId,
    required this.isCompleted,
    required this.isFavorite,
    this.score,
  });

  factory LessonProgressEntry.fromMap(Map<String, dynamic> m) => LessonProgressEntry(
        lessonId: m['lesson_id'] as String,
        isCompleted: m['is_completed'] as bool? ?? false,
        isFavorite: m['is_favorite'] as bool? ?? false,
        score: m['score'] as num?,
      );
}
