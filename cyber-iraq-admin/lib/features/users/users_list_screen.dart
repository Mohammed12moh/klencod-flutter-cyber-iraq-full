import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/users_admin_provider.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  String _query = '';

  String _levelLabel(String l) {
    switch (l) {
      case 'intermediate':
        return 'متوسط';
      case 'advanced':
        return 'متقدم';
      default:
        return 'مبتدئ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersSearchProvider(_query));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة المستخدمين')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'البحث بالاسم أو البريد الإلكتروني',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return const Center(child: Text('لا يوجد مستخدمون مطابقون.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                u.isActive ? null : Theme.of(context).colorScheme.error.withOpacity(0.2),
                            child: Icon(u.isAdmin ? Icons.admin_panel_settings : Icons.person),
                          ),
                          title: Text(u.displayName?.isNotEmpty == true ? u.displayName! : (u.email ?? '')),
                          subtitle: Text(
                              '${u.email ?? ''}\nالمستوى: ${_levelLabel(u.currentLevel)} · ${u.points} نقطة'
                              '${u.isActive ? '' : ' · معطّل'}'),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) async {
                              final svc = ref.read(usersAdminServiceProvider);
                              switch (action) {
                                case 'toggle_active':
                                  await svc.setActive(u.id, !u.isActive);
                                  break;
                                case 'grant_admin':
                                  await svc.grantAdmin(u.id);
                                  break;
                                case 'revoke_admin':
                                  await svc.revokeAdmin(u.id);
                                  break;
                              }
                              ref.invalidate(usersSearchProvider(_query));
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'toggle_active',
                                child: Text(u.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
                              ),
                              if (!u.isAdmin)
                                const PopupMenuItem(value: 'grant_admin', child: Text('منح صلاحية مدير'))
                              else
                                const PopupMenuItem(value: 'revoke_admin', child: Text('سحب صلاحية مدير')),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => const Center(child: Text('تعذر تحميل المستخدمين.')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
