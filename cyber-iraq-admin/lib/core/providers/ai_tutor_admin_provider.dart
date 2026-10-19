import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_tutor_admin_service.dart';

final aiTutorAdminServiceProvider = Provider<AiTutorAdminService>((ref) => AiTutorAdminService());

final aiTutorEnabledProvider = FutureProvider<bool>((ref) {
  return ref.watch(aiTutorAdminServiceProvider).isEnabled();
});

final aiTutorUsageProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(aiTutorAdminServiceProvider).usageStats();
});
