import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clarity_ai/models/v2_models.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';
import 'package:clarity_ai/core/services/database_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassicQuizPage extends ConsumerStatefulWidget {
  final QuizData quiz;
  const ClassicQuizPage({super.key, required this.quiz});

  @override
  ConsumerState<ClassicQuizPage> createState() => _ClassicQuizPageState();
}

class _ClassicQuizPageState extends ConsumerState<ClassicQuizPage> {
  late List<dynamic> _questions;
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _correctCount = 0;

  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _questions = jsonDecode(widget.quiz.contentJson);
  }

  void _checkAnswer() {
    setState(() {
      _showAnswer = true;
    });
  }

  void _nextQuestion(bool correct) {
    if (correct) _correctCount++;
    
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
        _answerController.clear();
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final score = (_correctCount / _questions.length) * 100;
    widget.quiz.score = score;
    await DatabaseService.instance.updateQuiz(widget.quiz);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Sınav Bitti!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Skorunuz: %${score.toInt()}\n\nDoğru: $_correctCount\nYanlış: ${_questions.length - _correctCount}', 
          style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant)
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Ana Sayfaya Dön'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentQ = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Klasik Sınav', style: GoogleFonts.outfit(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Soru ${_currentIndex + 1} / ${_questions.length}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  Text('Doğru: $_correctCount', style: GoogleFonts.inter(color: Colors.green)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.helpCircle, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Soru:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentQ['question'] ?? '',
                            style: GoogleFonts.inter(fontSize: 18, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!_showAnswer) ...[
                      TextField(
                        controller: _answerController,
                        maxLines: 4,
                        style: GoogleFonts.inter(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Cevabınızı buraya yazın...',
                          hintStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _checkAnswer,
                          child: Text('Cevabı Kontrol Et', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ] else ...[
                      GlassCard(
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                        borderColor: colorScheme.primary.withValues(alpha: 0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Beklenen Anahtar Kelimeler:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                            const SizedBox(height: 8),
                            Text(currentQ['expectedAnswerKeyword'] ?? '', style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface)),
                            const SizedBox(height: 16),
                            Text('Detaylı Açıklama:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                            const SizedBox(height: 8),
                            Text(currentQ['explanation'] ?? '', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Kendinizi nasıl değerlendiriyorsunuz?', textAlign: TextAlign.center, style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () => _nextQuestion(false),
                              icon: const Icon(LucideIcons.xCircle),
                              label: const Text('Yanlış Bildim'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade500,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () => _nextQuestion(true),
                              icon: const Icon(LucideIcons.checkCircle),
                              label: const Text('Doğru Bildim'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
