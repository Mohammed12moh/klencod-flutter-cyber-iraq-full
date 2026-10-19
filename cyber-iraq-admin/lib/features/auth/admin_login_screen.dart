import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/admin_auth_provider.dart';
import '../../core/services/admin_auth_service.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorText;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      await ref.read(adminAuthServiceProvider).signIn(
            usernameOrEmail: _userCtrl.text.trim(),
            password: _passCtrl.text,
          );
      if (mounted) context.go('/dashboard');
    } on NotAdminException {
      setState(() => _errorText = 'هذا الحساب لا يملك صلاحية الدخول إلى لوحة الإدارة.');
    } on AuthException {
      setState(() => _errorText = 'اسم المستخدم أو كلمة المرور غير صحيحة.');
    } catch (_) {
      setState(() => _errorText = 'تعذر الاتصال بالخادم. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, size: 64, color: green),
                      const SizedBox(height: 12),
                      Text(
                        'سايبر العراق — لوحة الإدارة',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _userCtrl,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم أو البريد الإلكتروني',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(_errorText!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Text('دخول'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'بيانات تطوير فقط: kali / kali — يجب إنشاء حساب فعلي في Supabase ومنحه دور admin، '
                        'ثم تعطيل هذا الحساب قبل النشر العام.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
