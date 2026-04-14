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

class FlashcardsScreen extends StatefulWidget{
  final String? setId;
  const FlashcardsScreen({super.key, this.setId});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with SingleTickerProviderStateMixin{
  final _setsService = SetsService();

  List<Flashcard> _cards = [];
  StudySet? _studySet;
  int _currentIndex = 0;
  bool _isFlipped   = false;
  bool _isLoading   = true;
  String _error     = '';
  bool _sessionComplete = false;
  bool _sessionPointsAwarded = false;
  int _sessionPointsEarned = 0;

  late AnimationController _animCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState(){
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose(){
    _animCtrl.dispose();
    super.dispose();
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
      if (!mounted) return;
      setState((){
        _studySet = results[0] as StudySet?;
        _cards    = results[1] as List<Flashcard>;
        _sessionComplete = false;
        _sessionPointsAwarded = false;
        _sessionPointsEarned = 0;
        _isLoading = false;
      });
    }
    catch (e){
      if (!mounted) return;
      setState((){ _error = 'Failed to load flashcards.'; _isLoading = false; });
    }
  }

  void _flipCard(){
    _isFlipped ? _animCtrl.reverse() : _animCtrl.forward();
    setState(() => _isFlipped = !_isFlipped);
  }

  void _nextCard(){
    if (_currentIndex < _cards.length - 1){
      _animCtrl.reset();
      setState((){ _currentIndex++; _isFlipped = false; });
    } else {
      setState(() => _sessionComplete = true);
      _awardCompletionPoints();
    }
  }

  void _prevCard(){
    if (_currentIndex > 0){
      _animCtrl.reset();
      setState((){ _currentIndex--; _isFlipped = false; });
    }
  }

  Future<void> _awardCompletionPoints() async {
    if (_sessionPointsAwarded) return;
    _sessionPointsAwarded = true;
    int pointsEarned = RewardsService
        .rewardEvents[RewardEventType.flashcardSession]!
        .points;

    final rewards = RewardsScope.of(context);
    await rewards.award(RewardEventType.flashcardSession);
    if (_cards.length >= 5) {
      await rewards.award(RewardEventType.cardsStudied);
      pointsEarned += RewardsService.rewardEvents[RewardEventType.cardsStudied]!.points;
    }

    if (!mounted) return;
    setState(() {
      _sessionPointsEarned = pointsEarned;
    });
  }

  void _restartSession() {
    _animCtrl.reset();
    setState(() {
      _currentIndex = 0;
      _isFlipped = false;
      _sessionComplete = false;
      _sessionPointsAwarded = false;
      _sessionPointsEarned = 0;
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
          _studySet?.title ?? 'Flashcards',
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
          : _cards.isEmpty
          ? const Center(
          child: Text('No cards in this set.',
              style: TextStyle(color: AppColors.textSub)))
          : _sessionComplete
          ? _buildSessionComplete()
          : _buildStudyView(),
    );
  }

  Widget _buildSessionComplete() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Session Complete',
              style: TextStyle(
                color: AppColors.textSub,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _studySet?.title ?? 'Flashcards',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '+$_sessionPointsEarned points earned!',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _restartSession,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x334F6FFF)),
                ),
                child: const Text(
                  'Restart Set',
                  style: TextStyle(
                    color: AppColors.textLink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => widget.setId != null
                  ? context.go('/sets/${widget.setId}')
                  : context.go('/dashboard'),
              child: const Text('Back to Set'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyView(){
    final card = _cards[_currentIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        children: [
          //progress bar and counter
          Row(
            children: [
              Text(
                '${_currentIndex + 1} / ${_cards.length}',
                style: const TextStyle(
                    color: AppColors.textSub, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _cards.length,
                    minHeight: 4,
                    backgroundColor: const Color(0x1A6378FF),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          //flip card
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (context, _){
                  final angle        = _flipAnim.value * pi;
                  final isShowingBack = angle > pi / 2;

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isShowingBack
                            ? const Color(0xFF12103A)   // violet-tinted back
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isShowingBack
                              ? const Color(0x408B6FFF)
                              : AppColors.cardBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isShowingBack
                                ? AppColors.accent
                                : AppColors.primary)
                                .withOpacity(0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Transform(
                        transform: Matrix4.identity()
                          ..rotateY(isShowingBack ? pi : 0),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Label pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isShowingBack
                                      ? const Color(0x338B6FFF)
                                      : AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isShowingBack ? 'DEFINITION' : 'TERM',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                    color: isShowingBack
                                        ? AppColors.accent
                                        : AppColors.textLink,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                isShowingBack
                                    ? card.definition
                                    : card.term,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 14),
          const Text(
            'Tap card to flip',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 24),

          //navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navButton(
                icon: Icons.arrow_back_ios_new_rounded,
                enabled: _currentIndex > 0,
                onTap: _prevCard,
              ),

              //centre counter
              Column(
                children: [
                  Text(
                    '${_currentIndex + 1}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    'of ${_cards.length}',
                    style: const TextStyle(
                        color: AppColors.textSub, fontSize: 12),
                  ),
                ],
              ),

              _navButton(
                icon: Icons.arrow_forward_ios_rounded,
                enabled: _currentIndex < _cards.length - 1,
                onTap: _nextCard,
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }){
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primarySoft : const Color(0x0DFFFFFF),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? const Color(0x334F6FFF)
                : const Color(0x1AFFFFFF),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.textLink : AppColors.textMuted,
        ),
      ),
    );
  }
}
