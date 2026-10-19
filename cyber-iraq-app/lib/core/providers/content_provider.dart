import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_path.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../services/content_service.dart';

final contentServiceProvider = Provider<ContentService>((ref) => ContentService());

final pathsProvider = FutureProvider<List<LearningPath>>((ref) {
  return ref.watch(contentServiceProvider).fetchPaths();
});

final lessonsForPathProvider =
    FutureProvider.family<List<Lesson>, String>((ref, pathId) {
  return ref.watch(contentServiceProvider).fetchLessons(pathId);
});

final lessonProvider = FutureProvider.family<Lesson?, String>((ref, lessonId) {
  return ref.watch(contentServiceProvider).fetchLesson(lessonId);
});

final myProgressProvider = FutureProvider<List<LessonProgressEntry>>((ref) {
  return ref.watch(contentServiceProvider).fetchMyProgress();
});

final myProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(contentServiceProvider).fetchMyProfile();
});

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(contentServiceProvider).fetchNotifications();
});
