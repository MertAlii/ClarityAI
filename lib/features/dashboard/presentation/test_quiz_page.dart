import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clarity_ai/models/v2_models.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';

class TestQuizPage extends StatefulWidget {
  final QuizData quiz;
  const TestQuizPage({super.key, required this.quiz});

  @override
  State<TestQuizPage> createState() => _TestQuizPageState();
}

class _TestQuizPageState extends State<TestQuizPage> {
  late List<Map<String, dynamic>> _questions;
  int _currentIndex = 0;
  String? _selectedOption;
  bool _isAnswered = false;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _parseQuiz();
  }

  void _parseQuiz() {
    try {
      final List<dynamic> parsed = jsonDecode(widget.quiz.contentJson);
      _questions = parsed.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      _questions = [];
    }
  }

  void _selectOption(String option) {
    if (_isAnswered) return;
    
    setState(() {
      _selectedOption = option;
      _isAnswered = true;
      
      final correctAnswer = _questions[_currentIndex]['answer'];
      if (option == correctAnswer) {
        _correctCount++;
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswered = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Bitti!'),
        content: Text('Skorunuz: $_correctCount / ${_questions.length}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Kapat'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test Sınavı')),
        body: const Center(child: Text('Geçerli test sorusu bulunamadı.')),
      );
    }

    final questionData = _questions[_currentIndex];
    final questionText = questionData['question'] ?? '';
    final List<dynamic> options = questionData['options'] ?? [];
    final correctAnswer = questionData['answer'] ?? '';
    final explanation = questionData['explanation'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${_currentIndex + 1} / ${_questions.length}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              child: Text(
                questionText,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 24),
            ...options.map((opt) {
              final String optionText = opt.toString();
              bool isSelected = _selectedOption == optionText;
              bool isCorrect = optionText == correctAnswer;
              
              Color? borderColor;
              Color? bgColor;
              IconData? icon;

              if (_isAnswered) {
                if (isCorrect) {
                  borderColor = const Color(0xFF22C55E); // success
                  bgColor = const Color(0xFF22C55E).withOpacity(0.1);
                  icon = LucideIcons.checkCircle;
                } else if (isSelected && !isCorrect) {
                  borderColor = const Color(0xFFEF4444); // error
                  bgColor = const Color(0xFFEF4444).withOpacity(0.1);
                  icon = LucideIcons.xCircle;
                }
              } else if (isSelected) {
                borderColor = Theme.of(context).primaryColor;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () => _selectOption(optionText),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor ?? Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                        width: isSelected || (_isAnswered && isCorrect) ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontWeight: isSelected || (_isAnswered && isCorrect) ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, color: borderColor),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            }),
            
            if (_isAnswered) ...[
              const SizedBox(height: 24),
              GlassCard(
                borderColor: const Color(0xFF84CC16).withOpacity(0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.info, color: Color(0xFF84CC16), size: 20),
                        const SizedBox(width: 8),
                        Text('Açıklama', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF84CC16))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(explanation),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_currentIndex < _questions.length - 1 ? 'Sıradaki Soru' : 'Sınavı Bitir'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
