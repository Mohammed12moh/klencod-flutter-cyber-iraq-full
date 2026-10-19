import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/paths/path_detail_screen.dart';
import '../../features/lessons/lesson_detail_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/ai_tutor/ai_tutor_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final signedIn = Supabase.instance.client.auth.currentSession != null;
      final goingToAuth = ['/login', '/signup', '/forgot-password']
          .contains(state.matchedLocation);

      if (!signedIn && !goingToAuth) return '/login';
      if (signedIn && goingToAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (c, s) => const SignupScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (c, s) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
      GoRoute(
        path: '/paths/:id',
        builder: (c, s) => PathDetailScreen(
          pathId: s.pathParameters['id']!,
          pathTitle: s.extra as String?,
        ),
      ),
      GoRoute(
        path: '/lessons/:id',
        builder: (c, s) => LessonDetailScreen(lessonId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/lessons/:id/quiz',
        builder: (c, s) => QuizScreen(lessonId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/ai-tutor', builder: (c, s) => const AiTutorScreen()),
    ],
  );
});

/// Bridges a Stream to Listenable so GoRouter re-evaluates `redirect`
/// whenever Supabase's auth state changes.
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
