import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/users_admin_service.dart';

final usersAdminServiceProvider = Provider<UsersAdminService>((ref) => UsersAdminService());

final usersSearchProvider =
    FutureProvider.family<List<AdminUserRow>, String>((ref, query) {
  return ref.watch(usersAdminServiceProvider).search(query);
});
