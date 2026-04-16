import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/flashcard.dart';
import '../models/studyset.dart';
import '../services/localstorage.dart';
import '../services/rewards_controller.dart';
import '../services/setsService.dart';
import '../widgets/appButton.dart';
import '../widgets/appField.dart';

class SetDetailScreen extends StatefulWidget {
  final String setId;

  const SetDetailScreen({
    super.key,
    required this.setId,
  });

  @override
  State<SetDetailScreen> createState() => _SetDetailScreenState();
}

class _SetDetailScreenState extends State<SetDetailScreen> {
  final _setsService = SetsService();
  final _termCtrl = TextEditingController();
  final _definitionCtrl = TextEditingController();

  StudySet? _studySet;
  List<Flashcard> _cards = [];
  int? _editingCardId;

  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _termCtrl.dispose();
    _definitionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await Future.wait([
        _setsService.getStudySetById(widget.setId),
        _setsService.getCardsForSet(widget.setId),
      ]);

      final setData = results[0] as StudySet?;
      final cardData = results[1] as List<Flashcard>;

      if (!mounted) return;

      if (setData == null) {
        setState(() {
          _error = 'Study set not found.';
          _isLoading = false;
        });
        return;
      }

      await LocalStorageService.saveString(
        'last_set',
        jsonEncode(setData.toJson()),
      );

      setState(() {
        _studySet = setData;
        _cards = cardData;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load this study set.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubmitCard() async {
    if (_termCtrl.text.trim().isEmpty || _definitionCtrl.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = '';
    });

    try {
      if (_editingCardId != null) {
        await _setsService.updateCard(
          cardId: _editingCardId!,
          term: _termCtrl.text,
          definition: _definitionCtrl.text,
        );
      } else {
        await _setsService.createCard(
          setId: widget.setId,
          term: _termCtrl.text,
          definition: _definitionCtrl.text,
        );
      }

      _termCtrl.clear();
      _definitionCtrl.clear();

      setState(() {
        _editingCardId = null;
        _isSaving = false;
      });

      await _loadData();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save flashcard.';
        _isSaving = false;
      });
    }
  }

  void _startEditing(Flashcard card) {
    _termCtrl.text = card.term;
    _definitionCtrl.text = card.definition;
    setState(() => _editingCardId = card.id);
  }

  void _cancelEdit() {
    _termCtrl.clear();
    _definitionCtrl.clear();
    setState(() => _editingCardId = null);
  }

  Future<void> _deleteCard(int cardId) async {
    final confirmed = await _showConfirmDialog('Delete this flashcard?');
    if (!confirmed) return;

    try {
      await _setsService.deleteCard(cardId);
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to delete card.');
    }
  }

  Future<void> _deleteSet() async {
    if (_studySet == null) return;

    final confirmed = await _showConfirmDialog(
      'Delete the entire set "${_studySet!.title}"?\nThis cannot be undone.',
    );

    if (!confirmed) return;

    try {
      await _setsService.deleteStudySet(_studySet!.id);
      if (mounted) context.go('/dashboard');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to delete study set.');
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    final colors = rewardsController.activeTheme.colors;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          'Confirm',
          style: TextStyle(color: colors.text),
        ),
        content: Text(
          message,
          style: TextStyle(color: colors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: colors.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFF87171)),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rewardsController,
      builder: (context, _) {
        final colors = rewardsController.activeTheme.colors;

        if (_isLoading) {
          return Scaffold(
            backgroundColor: colors.bg,
            body: Center(
              child: CircularProgressIndicator(color: colors.primary),
            ),
          );
        }

        if (_error.isNotEmpty && _studySet == null) {
          return Scaffold(
            backgroundColor: colors.bg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Failed to load this study set.',
                      style: TextStyle(color: Color(0xFFF87171)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Back to Dashboard',
                      style: AppButtonStyle.secondary,
                      onPressed: () => context.go('/dashboard'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: colors.bg,
          appBar: AppBar(
            backgroundColor: colors.bg,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: colors.textSub),
              onPressed: () => context.go('/dashboard'),
            ),
            title: Text(
              _studySet?.title ?? 'Study Set',
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFF87171),
                ),
                onPressed: _deleteSet,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: colors.border),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colors),
                const SizedBox(height: 20),
                _buildActionButtons(colors),
                const SizedBox(height: 20),
                _buildFormCard(colors),
                const SizedBox(height: 22),
                Text(
                  'Flashcards',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (_cards.isEmpty)
                  _buildEmptyCards(colors)
                else
                  ..._cards.map((card) => _buildCardTile(card, colors)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(dynamic colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _studySet?.description ?? '',
            style: TextStyle(
              color: colors.textSub,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_cards.length} cards',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic colors) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Flashcards',
            style: AppButtonStyle.secondary,
            onPressed: _cards.isEmpty
                ? null
                : () => context.go('/flashcards?setId=${widget.setId}'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'Quiz',
            style: AppButtonStyle.secondary,
            onPressed: _cards.isEmpty
                ? null
                : () => context.go('/quiz?setId=${widget.setId}'),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editingCardId != null ? 'Edit Flashcard' : 'Add Flashcard',
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 14),
          AppField(
            label: 'Term',
            placeholder: 'Enter term',
            controller: _termCtrl,
          ),
          AppField(
            label: 'Definition',
            placeholder: 'Enter definition',
            controller: _definitionCtrl,
            maxLines: 3,
          ),
          if (_error.isNotEmpty) ...[
            Text(
              _error,
              style: const TextStyle(
                color: Color(0xFFF87171),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _editingCardId != null ? 'Save Changes' : 'Add Card',
                  isLoading: _isSaving,
                  onPressed: _handleSubmitCard,
                ),
              ),
              if (_editingCardId != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    style: AppButtonStyle.secondary,
                    onPressed: _cancelEdit,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCards(dynamic colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.style_outlined,
            color: colors.primary,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            'No flashcards yet',
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first card above to start studying.',
            style: TextStyle(color: colors.textSub),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(Flashcard card, dynamic colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.layers_rounded,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.term,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.definition,
                    style: TextStyle(
                      color: colors.textSub,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: colors.primary),
              onPressed: () => _startEditing(card),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Color(0xFFF87171),
              ),
              onPressed: () => _deleteCard(card.id),
            ),
          ],
        ),
      ),
    );
  }
}