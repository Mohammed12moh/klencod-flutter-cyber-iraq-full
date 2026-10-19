import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/admin_login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/paths/paths_list_screen.dart';
import '../../features/lessons/lessons_list_screen.dart';
import '../../features/quiz/quiz_questions_list_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/ai_tutor/ai_tutor_settings_screen.dart';
import '../../features/users/users_list_screen.dart';
import '../../features/audit/audit_log_screen.dart';
import '../../features/settings/settings_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final signedIn = Supabase.instance.client.auth.currentSession != null;
      final goingToLogin = state.matchedLocation == '/login';

      if (!signedIn && !goingToLogin) return '/login';
      if (signedIn && goingToLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const AdminLoginScreen()),
      GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
      GoRoute(path: '/paths', builder: (c, s) => const PathsListScreen()),
      GoRoute(
        path: '/paths/:id/lessons',
        builder: (c, s) => LessonsListScreen(
          pathId: s.pathParameters['id']!,
          pathTitle: s.extra as String?,
        ),
      ),
      GoRoute(
        path: '/lessons/:id/quiz',
        builder: (c, s) => QuizQuestionsListScreen(
          lessonId: s.pathParameters['id']!,
          lessonTitle: s.extra as String?,
        ),
      ),
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: '/ai-tutor-settings', builder: (c, s) => const AiTutorSettingsScreen()),
      GoRoute(path: '/users', builder: (c, s) => const UsersListScreen()),
      GoRoute(path: '/audit-log', builder: (c, s) => const AuditLogScreen()),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
