import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_path.dart';
import '../models/lesson.dart';
import '../services/content_admin_service.dart';

final contentAdminServiceProvider = Provider<ContentAdminService>((ref) => ContentAdminService());

final allPathsProvider = FutureProvider<List<LearningPath>>((ref) {
  return ref.watch(contentAdminServiceProvider).fetchAllPaths();
});

final allLessonsForPathProvider =
    FutureProvider.family<List<Lesson>, String>((ref, pathId) {
  return ref.watch(contentAdminServiceProvider).fetchAllLessons(pathId);
});
