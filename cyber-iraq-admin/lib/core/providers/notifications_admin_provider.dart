import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notifications_admin_service.dart';

final notificationsAdminServiceProvider =
    Provider<NotificationsAdminService>((ref) => NotificationsAdminService());

final notificationsAdminListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(notificationsAdminServiceProvider).fetchAll();
});
