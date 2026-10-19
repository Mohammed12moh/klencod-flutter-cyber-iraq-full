import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _errorText;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorText = 'أدخل بريداً إلكترونياً صالحاً');
      return;
    }
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      await ref.read(authServiceProvider).resetPassword(email);
      setState(() => _sent = true);
    } catch (_) {
      setState(() => _errorText = 'تعذر إرسال رابط الاستعادة. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('استعادة كلمة المرور')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_sent)
                  const Text('إذا كان البريد مسجلاً لدينا، سيصلك رابط لإعادة تعيين كلمة المرور.')
                else ...[
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(_errorText!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('إرسال رابط الاستعادة'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
