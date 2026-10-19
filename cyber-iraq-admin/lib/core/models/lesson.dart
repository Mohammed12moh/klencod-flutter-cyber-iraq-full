class Lesson {
  final String id;
  final String pathId;
  final String title;
  final String? description;
  final List<String> objectives;
  final String? contentMd;
  final String difficulty;
  final int estimatedMinutes;
  final int sortOrder;
  final String? videoUrl;
  final String? imageUrl;
  final bool isPublished;
  final int passScore;

  Lesson({
    required this.id,
    required this.pathId,
    required this.title,
    this.description,
    required this.objectives,
    this.contentMd,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.sortOrder,
    this.videoUrl,
    this.imageUrl,
    required this.isPublished,
    this.passScore = 70,
  });

  factory Lesson.fromMap(Map<String, dynamic> m) => Lesson(
        id: m['id'] as String,
        pathId: m['path_id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        objectives: (m['objectives'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        contentMd: m['content_md'] as String?,
        difficulty: m['difficulty'] as String? ?? 'beginner',
        estimatedMinutes: (m['estimated_minutes'] as int?) ?? 15,
        sortOrder: (m['sort_order'] as int?) ?? 0,
        videoUrl: m['video_url'] as String?,
        imageUrl: m['image_url'] as String?,
        isPublished: m['is_published'] as bool? ?? false,
        passScore: (m['pass_score'] as int?) ?? 70,
      );
}
