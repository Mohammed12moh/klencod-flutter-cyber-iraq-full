import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
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
      await ref.read(authServiceProvider).signUp(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            displayName: _nameCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الحساب. تحقق من بريدك لتأكيده إذا لزم.')),
        );
        context.go('/home');
      }
    } on AuthException catch (e) {
      setState(() => _errorText = _mapError(e.message));
    } catch (_) {
      setState(() => _errorText = 'تعذر إنشاء الحساب. تحقق من الإنترنت وحاول مجدداً.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapError(String raw) {
    if (raw.toLowerCase().contains('already registered') ||
        raw.toLowerCase().contains('already exists')) {
      return 'هذا البريد الإلكتروني مستخدم مسبقاً.';
    }
    if (raw.toLowerCase().contains('password')) {
      return 'كلمة المرور لا تحقق الشروط المطلوبة.';
    }
    return 'حدث خطأ أثناء إنشاء الحساب. حاول مرة أخرى.';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إنشاء حساب')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'أدخل اسمك' : null,
                  ),
                  const SizedBox(height: 16),
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
                      if (v.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                      return null;
                    },
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('إنشاء الحساب'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
