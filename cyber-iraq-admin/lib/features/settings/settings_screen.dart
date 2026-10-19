import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/platform_settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _supportCtrl = TextEditingController();
  final _privacyCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  bool _maintenance = false;
  bool _loaded = false;
  bool _saving = false;

  void _fill(Map<String, dynamic> values) {
    _nameCtrl.text = (values['app_name'] as String?) ?? 'سايبر العراق';
    _descCtrl.text = (values['app_description'] as String?) ?? '';
    _supportCtrl.text = (values['support_contact'] as String?) ?? '';
    _privacyCtrl.text = (values['privacy_policy_url'] as String?) ?? '';
    _termsCtrl.text = (values['terms_url'] as String?) ?? '';
    _maintenance = (values['maintenance_mode'] as bool?) ?? false;
    _loaded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(platformSettingsServiceProvider).save({
        'app_name': _nameCtrl.text.trim(),
        'app_description': _descCtrl.text.trim(),
        'support_contact': _supportCtrl.text.trim(),
        'privacy_policy_url': _privacyCtrl.text.trim(),
        'terms_url': _termsCtrl.text.trim(),
        'maintenance_mode': _maintenance,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _supportCtrl.dispose();
    _privacyCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(platformSettingsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إعدادات المنصة')),
        body: settingsAsync.when(
          data: (values) {
            if (!_loaded) _fill(values);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم التطبيق'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'وصف المنصة'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _supportCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'رابط/بريد الدعم'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _privacyCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'رابط سياسة الخصوصية'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _termsCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'رابط شروط الاستخدام'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('وضع الصيانة'),
                  subtitle: const Text('إيقاف وصول المستخدمين مؤقتاً للتطبيق'),
                  value: _maintenance,
                  onChanged: (v) => setState(() => _maintenance = v),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('حفظ الإعدادات'),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => const Center(child: Text('تعذر تحميل الإعدادات.')),
        ),
      ),
    );
  }
}
