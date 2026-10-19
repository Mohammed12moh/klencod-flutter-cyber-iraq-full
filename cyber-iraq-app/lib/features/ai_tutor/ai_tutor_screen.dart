import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ChatMessage {
  final String text;
  final bool fromUser;
  _ChatMessage(this.text, this.fromUser);
}

/// Chats with the AI tutor. All requests go through the `ai-tutor` Edge
/// Function — the API key never touches this app, and the server enforces
/// the daily message cap and the feature's on/off flag.
class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  String? _error;

  static const int _maxLength = 1500;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (text.length > _maxLength) {
      setState(() => _error = 'الرسالة طويلة جداً (الحد الأقصى $_maxLength حرف).');
      return;
    }
    setState(() {
      _messages.add(_ChatMessage(text, true));
      _controller.clear();
      _sending = true;
      _error = null;
    });
    _scrollToEnd();
    try {
      final res = await Supabase.instance.client.functions
          .invoke('ai-tutor', body: {'message': text});
      if (res.status == 429) {
        setState(() => _error = 'وصلت للحد الأقصى من الرسائل اليوم. حاول غداً.');
      } else if (res.status == 403) {
        setState(() => _error = 'المدرس الذكي معطّل حالياً من الإدارة.');
      } else if (res.status != 200 || res.data == null) {
        setState(() => _error = 'تعذر الحصول على رد. حاول مرة أخرى.');
      } else {
        final reply = (res.data as Map)['reply'] as String? ?? '';
        setState(() => _messages.add(_ChatMessage(reply, false)));
      }
    } catch (_) {
      setState(() => _error = 'تعذر الاتصال بالخادم.');
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المدرس الذكي')),
        body: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'اسألني عن أي شيء بالأمن السيبراني: أوامر Linux، شرح ثغرة، أو مراجعة درس.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        return Align(
                          alignment: m.fromUser ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.78),
                            decoration: BoxDecoration(
                              color: m.fromUser
                                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(m.text),
                          ),
                        );
                      },
                    ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: _maxLength,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        decoration: const InputDecoration(hintText: 'اكتب سؤالك هنا...'),
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
