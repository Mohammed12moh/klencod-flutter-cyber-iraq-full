class LearningPath {
  final String id;
  final String title;
  final String? description;
  final String level; // beginner | intermediate | advanced
  final int sortOrder;
  final String? icon;
  final bool isPublished;

  LearningPath({
    required this.id,
    required this.title,
    this.description,
    required this.level,
    required this.sortOrder,
    this.icon,
    required this.isPublished,
  });

  factory LearningPath.fromMap(Map<String, dynamic> m) => LearningPath(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        level: m['level'] as String? ?? 'beginner',
        sortOrder: (m['sort_order'] as int?) ?? 0,
        icon: m['icon'] as String?,
        isPublished: m['is_published'] as bool? ?? false,
      );
}
