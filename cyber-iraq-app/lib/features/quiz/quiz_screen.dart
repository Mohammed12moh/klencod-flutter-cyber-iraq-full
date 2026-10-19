import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/quiz_provider.dart';
import '../../core/providers/content_provider.dart';
import '../../core/models/quiz_result.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String lessonId;
  const QuizScreen({super.key, required this.lessonId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final Map<String, String> _answers = {};
  bool _submitting = false;
  QuizResult? _result;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(quizServiceProvider)
          .submit(lessonId: widget.lessonId, answers: _answers);
      setState(() => _result = result);
      ref.invalidate(myProgressProvider);
    } catch (_) {
      setState(() => _error = 'تعذر إرسال الإجابات. تحقق من الاتصال وحاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _QuizResultView(result: _result!, onRetry: () => setState(() {
        _result = null;
        _answers.clear();
      }));
    }

    final questionsAsync = ref.watch(quizQuestionsProvider(widget.lessonId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اختبار الدرس')),
        body: questionsAsync.when(
          data: (questions) {
            if (questions.isEmpty) {
              return const Center(child: Text('لا يوجد اختبار متاح لهذا الدرس بعد.'));
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: questions.length,
                    itemBuilder: (context, i) {
                      final q = questions[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${i + 1}. ${q.question}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...q.options.map((opt) => RadioListTile<String>(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(opt.text),
                                    value: opt.id,
                                    groupValue: _answers[q.id],
                                    onChanged: (v) => setState(() => _answers[q.id] = v!),
                                  )),
                            ],
                          ),
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: (_submitting || _answers.length < questions.length)
                        ? null
                        : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('إرسال الإجابات'),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => const Center(child: Text('تعذر تحميل الاختبار.')),
        ),
      ),
    );
  }
}

class _QuizResultView extends StatelessWidget {
  final QuizResult result;
  final VoidCallback onRetry;
  const _QuizResultView({required this.result, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final color = result.passed ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('نتيجة الاختبار')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(result.passed ? Icons.emoji_events : Icons.replay, size: 48, color: color),
                    const SizedBox(height: 8),
                    Text('${result.score}%',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(result.passed
                        ? 'نجحت! الدرس الآن مكتمل.'
                        : 'لم تصل لدرجة النجاح (${result.passScore}%). راجع الدرس وحاول مجدداً.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('مراجعة الإجابات', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...result.results.map((r) => Card(
                  child: ListTile(
                    leading: Icon(r.correct ? Icons.check_circle : Icons.cancel,
                        color: r.correct ? Colors.green : Theme.of(context).colorScheme.error),
                    title: Text(r.correct ? 'إجابة صحيحة' : 'إجابة خاطئة'),
                    subtitle: r.explanation != null ? Text(r.explanation!) : null,
                  ),
                )),
            const SizedBox(height: 16),
            if (!result.passed)
              ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
