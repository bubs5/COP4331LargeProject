import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/flashcard.dart';
import '../models/rewards.dart';
import '../models/studyset.dart';
import '../services/rewardsProvider.dart';
import '../services/rewardsService.dart';
import '../services/setsService.dart';
import '../widgets/appButton.dart';

class QuizScreen extends StatefulWidget{
  final String? setId;
  const QuizScreen({super.key, this.setId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizQuestion{
  final Flashcard card;
  final List<String> options;
  final int correctIndex;
  _QuizQuestion({
    required this.card,
    required this.options,
    required this.correctIndex,
  });
}

class _QuizScreenState extends State<QuizScreen>{
  final _setsService = SetsService();
  final _rng = Random();

  StudySet? _studySet;
  List<_QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _score     = 0;
  bool _finished = false;
  bool _pointsAwarded = false;
  String _pointsBanner = '';

  bool _isLoading = true;
  String _error   = '';

  @override
  void initState(){
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async{
    if (widget.setId == null){
      setState((){ _error = 'No set selected.'; _isLoading = false; });
      return;
    }
    try{
      final results = await Future.wait([
        _setsService.getStudySetById(widget.setId!),
        _setsService.getCardsForSet(widget.setId!),
      ]);

      final setData = results[0] as StudySet?;
      final cards   = results[1] as List<Flashcard>;

      if (!mounted) return;

      if (cards.length < 2){
        setState((){
          _error = 'Need at least 2 cards to take a quiz.';
          _isLoading = false;
        });
        return;
      }

      setState((){
        _studySet  = setData;
        _questions = _buildQuestions(cards);
        _isLoading = false;
      });
    }
    catch (e){
      if (!mounted) return;
      setState((){ _error = 'Failed to load quiz.'; _isLoading = false; });
    }
  }

  List<_QuizQuestion> _buildQuestions(List<Flashcard> cards){
    final shuffled       = List<Flashcard>.from(cards)..shuffle(_rng);
    final allDefinitions = cards.map((c) => c.definition).toList();

    return shuffled.map((card){
      final wrongs  = List<String>.from(allDefinitions)
        ..remove(card.definition)
        ..shuffle(_rng);
      final options = [card.definition, ...wrongs.take(3)]..shuffle(_rng);
      return _QuizQuestion(
        card: card,
        options: options,
        correctIndex: options.indexOf(card.definition),
      );
    }).toList();
  }

  void _selectAnswer(int index){
    if (_answered) return;
    setState((){
      _selectedIndex = index;
      _answered = true;
      if (index == _questions[_currentIndex].correctIndex) _score++;
    });
  }

  void _next(){
    if (_currentIndex < _questions.length - 1){
      setState((){
        _currentIndex++;
        _selectedIndex = null;
        _answered = false;
      });
    } else{
      setState(() => _finished = true);
      _awardQuizPoints();
    }
  }

  Future<void> _awardQuizPoints() async {
    if (_pointsAwarded) return;
    _pointsAwarded = true;
    final rewards = RewardsScope.of(context);
    final isPerfect = _score == _questions.length && _questions.isNotEmpty;
    if (isPerfect) {
      final points = RewardsService.rewardEvents[RewardEventType.quizPerfect]!.points;
      await rewards.award(RewardEventType.quizPerfect);
      _pointsBanner = 'Perfect score! You earned $points points!';
    } else {
      final points = RewardsService.rewardEvents[RewardEventType.quizComplete]!.points;
      await rewards.award(RewardEventType.quizComplete);
      _pointsBanner = 'Quiz complete! You earned $points points!';
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _restart(){
    final cards = _questions.map((q) => q.card).toList();
    setState((){
      _questions     = _buildQuestions(cards);
      _currentIndex  = 0;
      _selectedIndex = null;
      _answered      = false;
        _score         = 0;
        _finished      = false;
        _pointsAwarded = false;
        _pointsBanner = '';
      });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSub),
          onPressed: () => widget.setId != null
              ? context.go('/sets/${widget.setId}')
              : context.go('/dashboard'),
        ),
        title: Text(
          _studySet?.title ?? 'Quiz',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.cardBorder),
        ),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : _error.isNotEmpty
          ? Center(
          child: Text(_error,
              style: const TextStyle(color: AppColors.error)))
          : _finished
          ? _buildResults()
          : _buildQuizView(),
    );
  }

  Widget _buildQuizView(){
    final q = _questions[_currentIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //progress and score row
          Row(
            children: [
              Text(
                'Question ${_currentIndex + 1} of ${_questions.length}',
                style: const TextStyle(
                    color: AppColors.textSub, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_score / ${_currentIndex + (_answered ? 1 : 0)}',
                  style: const TextStyle(
                    color: AppColors.textLink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              minHeight: 4,
              backgroundColor: const Color(0x1A6378FF),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 28),

          //question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What is the definition of:',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSub),
                ),
                const SizedBox(height: 10),
                Text(
                  q.card.term,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          //answer options
          ...List.generate(q.options.length, (i){
            return _buildOption(q, i);
          }),

          const Spacer(),

          if (_answered)
            AppButton(
              label: _currentIndex < _questions.length - 1
                  ? 'Next Question →'
                  : 'See Results',
              onPressed: _next,
            ),
        ],
      ),
    );
  }

  Widget _buildOption(_QuizQuestion q, int i){
    final isCorrect  = i == q.correctIndex;
    final isSelected = i == _selectedIndex;

    Color borderColor;
    Color bgColor;
    Color textColor;
    Widget? trailingIcon;

    if (_answered){
      if (isCorrect){
        bgColor     = const Color(0x1A86EFAC);
        borderColor = const Color(0x4D86EFAC);
        textColor   = AppColors.success;
        trailingIcon = const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 18);
      }
      else if (isSelected){
        bgColor     = AppColors.errorBg;
        borderColor = const Color(0x4DF87171);
        textColor   = AppColors.error;
        trailingIcon = const Icon(Icons.cancel_rounded,
            color: AppColors.error, size: 18);
      }
      else{
        bgColor     = const Color(0x0DFFFFFF);
        borderColor = const Color(0x1AFFFFFF);
        textColor   = AppColors.textMuted;
        trailingIcon = null;
      }
    }
    else{
      bgColor     = AppColors.card;
      borderColor = isSelected
          ? const Color(0x664F6FFF)
          : AppColors.cardBorder;
      textColor   = AppColors.textPrimary;
      trailingIcon = null;
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // A/B/C/D
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _answered && isCorrect
                      ? const Color(0x3386EFAC)
                      : _answered && isSelected
                      ? const Color(0x33F87171)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + i), // A, B, C, D
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _answered && isCorrect
                          ? AppColors.success
                          : _answered && isSelected
                          ? AppColors.error
                          : AppColors.textLink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q.options[i],
                  style: TextStyle(fontSize: 14, color: textColor),
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

  Widget _buildResults(){
    final pct = (_score / _questions.length * 100).round();

    Color resultColor;
    String resultText;
    Color glowColor;

    if (pct >= 80){
      resultColor = AppColors.success;
      resultText  = 'Excellent!';
      glowColor   = const Color(0x2086EFAC);
    }
    else if (pct >= 60){
      resultColor = const Color(0xFFFBBF24);
      resultText  = 'Good Try!';
      glowColor   = const Color(0x20FBBF24);
    }
    else{
      resultColor = AppColors.error;
      resultText  = 'Keep Practicing!';
      glowColor   = AppColors.errorBg;
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_pointsBanner.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primarySoft,
                border: Border.all(color: const Color(0x334F6FFF)),
              ),
              child: Text(
                _pointsBanner,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textLink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 20),
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

          //score box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Text(
                  '$_score / ${_questions.length}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pct% correct',
                  style: const TextStyle(
                      color: AppColors.textSub, fontSize: 16),
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
