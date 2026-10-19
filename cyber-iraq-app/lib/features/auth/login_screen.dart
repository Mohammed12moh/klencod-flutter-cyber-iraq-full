import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      await ref.read(authServiceProvider).signIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      setState(() => _errorText = _mapError(e.message));
    } catch (_) {
      setState(() => _errorText = 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مجدداً.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapError(String raw) {
    if (raw.toLowerCase().contains('invalid login')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    }
    if (raw.toLowerCase().contains('email not confirmed')) {
      return 'الرجاء تأكيد بريدك الإلكتروني أولاً.';
    }
    return 'حدث خطأ أثناء تسجيل الدخول. حاول مرة أخرى.';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Icon(Icons.shield_outlined,
                        size: 72, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'سايبر العراق',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تعلّم الأمن السيبراني من الصفر',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                        if (!v.contains('@')) return 'بريد إلكتروني غير صالح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                        if (v.length < 6) return 'كلمة المرور قصيرة جداً';
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(_errorText!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('تسجيل الدخول'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('ليس لديك حساب؟'),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          child: const Text('إنشاء حساب'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
