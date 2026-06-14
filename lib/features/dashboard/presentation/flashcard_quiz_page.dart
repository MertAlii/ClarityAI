import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:clarity_ai/models/v2_models.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';

class FlashcardQuizPage extends StatefulWidget {
  final QuizData quiz;
  const FlashcardQuizPage({super.key, required this.quiz});

  @override
  State<FlashcardQuizPage> createState() => _FlashcardQuizPageState();
}

class _FlashcardQuizPageState extends State<FlashcardQuizPage> {
  late List<Map<String, dynamic>> _cards;
  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _parseQuiz();
  }

  void _parseQuiz() {
    try {
      final List<dynamic> parsed = jsonDecode(widget.quiz.contentJson);
      _cards = parsed.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      _cards = [];
    }
  }

  void _flipCard() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      HapticFeedback.selectionClick();
      setState(() {
        _isFlipped = false;
        _currentIndex++;
      });
    } else {
      HapticFeedback.mediumImpact();
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Tebrikler!'),
        content: const Text('Tüm hafıza kartlarını tamamladınız.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Bitir'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hafıza Kartları')),
        body: const Center(child: Text('Geçerli hafıza kartı bulunamadı.')),
      );
    }

    final card = _cards[_currentIndex];
    final question = card['question'] ?? '';
    final answer = card['answer'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Kart ${_currentIndex + 1} / ${_cards.length}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    transformAlignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_isFlipped ? pi : 0),
                    child: _isFlipped 
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _buildCardContent(answer, true)
                          )
                        : _buildCardContent(question, false),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Bilmiyorum logic
                        _nextCard();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
                      ),
                      child: const Text('Bilmiyorum'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Biliyorum logic
                        _nextCard();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Biliyorum'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(String text, bool isBack) {
    return GlassCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isBack ? 'Cevap' : 'Soru',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: isBack ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
