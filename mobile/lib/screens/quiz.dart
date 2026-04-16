import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/flashcard.dart';
import '../models/studyset.dart';
import '../services/rewards_controller.dart';
import '../services/setsService.dart';
import '../widgets/appButton.dart';

class QuizScreen extends StatefulWidget {
  final String? setId;

  const QuizScreen({
    super.key,
    this.setId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizQuestion {
  final Flashcard card;
  final List<String> options;
  final int correctIndex;

  _QuizQuestion({
    required this.card,
    required this.options,
    required this.correctIndex,
  });
}

class _QuizScreenState extends State<QuizScreen> {
  final _setsService = SetsService();
  final _rng = Random();

  StudySet? _studySet;
  List<Flashcard> _cards = [];
  List<_QuizQuestion> _questions = [];

  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _answered = false;
  bool _finished = false;
  bool _isLoading = true;
  bool _awardedQuizPoints = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    if (widget.setId == null) {
      setState(() {
        _error = 'No set selected.';
        _isLoading = false;
      });
      return;
    }

    try {
      final results = await Future.wait([
        _setsService.getStudySetById(widget.setId!),
        _setsService.getCardsForSet(widget.setId!),
      ]);

      final setData = results[0] as StudySet?;
      final cards = results[1] as List<Flashcard>;

      if (cards.isEmpty) {
        if (!mounted) return;
        setState(() {
          _studySet = setData;
          _cards = [];
          _isLoading = false;
        });
        return;
      }

      final questions = _buildQuestions(cards);

      if (!mounted) return;
      setState(() {
        _studySet = setData;
        _cards = cards;
        _questions = questions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load quiz.';
        _isLoading = false;
      });
    }
  }

  List<_QuizQuestion> _buildQuestions(List<Flashcard> cards) {
    return cards.map((card) {
      final otherDefinitions = cards
          .where((c) => c.id != card.id)
          .map((c) => c.definition)
          .toList()
        ..shuffle(_rng);

      final options = <String>[card.definition];
      options.addAll(otherDefinitions.take(3));
      options.shuffle(_rng);

      return _QuizQuestion(
        card: card,
        options: options,
        correctIndex: options.indexOf(card.definition),
      );
    }).toList();
  }

  void _selectAnswer(int index) {
    if (_answered) return;

    final current = _questions[_currentIndex];
    final correct = index == current.correctIndex;

    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (correct) _score++;
    });
  }

  Future<void> _next() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _answered = false;
      });
    } else {
      if (!_awardedQuizPoints) {
        _awardedQuizPoints = true;
        await rewardsController.award('quiz_complete');
        if (_score == _questions.length) {
          await rewardsController.award('quiz_perfect');
        }
      }

      if (!mounted) return;
      setState(() => _finished = true);
    }
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _selectedIndex = null;
      _answered = false;
      _finished = false;
      _awardedQuizPoints = false;
      _questions = _buildQuestions(_cards);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rewardsController,
      builder: (context, _) {
        final colors = rewardsController.activeTheme.colors;

        return Scaffold(
          backgroundColor: colors.bg,
          appBar: AppBar(
            backgroundColor: colors.bg,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: colors.textSub),
              onPressed: () => widget.setId != null
                  ? context.go('/sets/${widget.setId}')
                  : context.go('/dashboard'),
            ),
            title: Text(
              _studySet?.title ?? 'Quiz',
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: colors.border),
            ),
          ),
          body: _isLoading
              ? Center(
            child: CircularProgressIndicator(color: colors.primary),
          )
              : _error.isNotEmpty
              ? Center(
            child: Text(
              _error,
              style: const TextStyle(color: Color(0xFFF87171)),
            ),
          )
              : _cards.isEmpty
              ? Center(
            child: Text(
              'No cards in this set.',
              style: TextStyle(color: colors.textSub),
            ),
          )
              : _finished
              ? _buildResults(colors)
              : _buildQuizView(colors),
        );
      },
    );
  }

  Widget _buildQuizView(dynamic colors) {
    final q = _questions[_currentIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question ${_currentIndex + 1} of ${_questions.length}',
                style: TextStyle(
                  color: colors.textSub,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$_score / ${_currentIndex + (_answered ? 1 : 0)}',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              minHeight: 6,
              backgroundColor: colors.border.withOpacity(0.45),
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What is the definition of:',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSub,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  q.card.term,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(q.options.length, (i) => _buildOption(q, i, colors)),
          const Spacer(),
          if (_answered)
            AppButton(
              label: _currentIndex < _questions.length - 1
                  ? 'Next Question →'
                  : 'See Results',
              onPressed: () => _next(),
            ),
        ],
      ),
    );
  }

  Widget _buildOption(_QuizQuestion q, int i, dynamic colors) {
    final isCorrect = i == q.correctIndex;
    final isSelected = i == _selectedIndex;

    Color borderColor;
    Color bgColor;
    Color textColor;
    Widget? trailingIcon;

    if (_answered) {
      if (isCorrect) {
        bgColor = const Color(0x1A86EFAC);
        borderColor = const Color(0x4D86EFAC);
        textColor = const Color(0xFF86EFAC);
        trailingIcon = const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF86EFAC),
          size: 18,
        );
      } else if (isSelected) {
        bgColor = const Color(0x1AF87171);
        borderColor = const Color(0x4DF87171);
        textColor = const Color(0xFFF87171);
        trailingIcon = const Icon(
          Icons.cancel_rounded,
          color: Color(0xFFF87171),
          size: 18,
        );
      } else {
        bgColor = colors.surface;
        borderColor = colors.border;
        textColor = colors.textSub;
      }
    } else {
      bgColor = colors.card;
      borderColor = isSelected
          ? colors.primary.withOpacity(0.45)
          : colors.border;
      textColor = colors.text;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _selectAnswer(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _answered && isCorrect
                      ? const Color(0x3386EFAC)
                      : _answered && isSelected
                      ? const Color(0x33F87171)
                      : colors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + i),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _answered && isCorrect
                          ? const Color(0xFF86EFAC)
                          : _answered && isSelected
                          ? const Color(0xFFF87171)
                          : colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q.options[i],
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                trailingIcon,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(dynamic colors) {
    final pct = (_score / _questions.length * 100).round();

    Color resultColor;
    String resultText;

    if (pct >= 80) {
      resultColor = const Color(0xFF86EFAC);
      resultText = 'Excellent!';
    } else if (pct >= 60) {
      resultColor = const Color(0xFFFBBF24);
      resultText = 'Good Try!';
    } else {
      resultColor = const Color(0xFFF87171);
      resultText = 'Keep Practicing!';
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            resultText,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: resultColor,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Text(
                  '$_score / ${_questions.length}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pct% correct',
                  style: TextStyle(
                    color: colors.textSub,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Try Again',
            onPressed: _restart,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Back to Set',
            style: AppButtonStyle.secondary,
            onPressed: () => widget.setId != null
                ? context.go('/sets/${widget.setId}')
                : context.go('/dashboard'),
          ),
        ],
      ),
    );
  }
}