import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/flashcard.dart';
import '../models/studyset.dart';
import '../services/rewards_controller.dart';
import '../services/setsService.dart';

class FlashcardsScreen extends StatefulWidget {
  final String? setId;

  const FlashcardsScreen({
    super.key,
    this.setId,
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  final _setsService = SetsService();

  List<Flashcard> _cards = [];
  StudySet? _studySet;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;
  bool _awardedSessionPoints = false;
  String _error = '';

  late AnimationController _animCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
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
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
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

      if (!mounted) return;

      final loadedCards = results[1] as List<Flashcard>;

      setState(() {
        _studySet = results[0] as StudySet?;
        _cards = loadedCards;
        _isLoading = false;
      });

      if (!_awardedSessionPoints && loadedCards.isNotEmpty) {
        _awardedSessionPoints = true;
        await rewardsController.award('flashcard_session');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load flashcards.';
        _isLoading = false;
      });
    }
  }

  void _flipCard() {
    _isFlipped ? _animCtrl.reverse() : _animCtrl.forward();
    setState(() => _isFlipped = !_isFlipped);
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      _animCtrl.reset();
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      _animCtrl.reset();
      setState(() {
        _currentIndex--;
        _isFlipped = false;
      });
    }
  }

  void _finishSession() {
    if (widget.setId != null) {
      context.go('/sets/${widget.setId}');
    } else {
      context.go('/dashboard');
    }
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
              _studySet?.title ?? 'Flashcards',
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
              : _buildStudyView(colors),
        );
      },
    );
  }

  Widget _buildStudyView(dynamic colors) {
    final card = _cards[_currentIndex];
    final progress = (_currentIndex + 1) / _cards.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Card ${_currentIndex + 1} of ${_cards.length}',
                style: TextStyle(
                  color: colors.textSub,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: colors.border.withOpacity(0.45),
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (context, child) {
                  final angle = _flipAnim.value * pi;
                  final isBack = angle > pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isFlipped
                              ? colors.primary.withOpacity(0.35)
                              : colors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.08),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..rotateY(isBack ? pi : 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isBack ? 'Definition' : 'Term',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              isBack ? card.definition : card.term,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Tap card to flip',
                              style: TextStyle(
                                color: colors.textSub,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 22),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _navButton(
                      label: 'Previous',
                      icon: Icons.arrow_back_rounded,
                      onTap: _currentIndex > 0 ? _prevCard : null,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _navButton(
                      label: 'Next',
                      icon: Icons.arrow_forward_rounded,
                      onTap: _currentIndex < _cards.length - 1 ? _nextCard : null,
                      colors: colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _finishSession,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    backgroundColor: colors.card,
                    foregroundColor: colors.textSub,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Finish Session',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required dynamic colors,
  }) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? colors.primary.withOpacity(0.10) : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? colors.primary.withOpacity(0.22) : colors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled ? colors.primary : colors.textSub,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: enabled ? colors.primary : colors.textSub,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}