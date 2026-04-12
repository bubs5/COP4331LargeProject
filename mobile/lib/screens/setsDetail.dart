import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/studyset.dart';
import '../models/flashcard.dart';
import '../services/setsService.dart';
import '../services/localstorage.dart';
import '../widgets/appButton.dart';
import '../widgets/appField.dart';

class SetDetailScreen extends StatefulWidget{
  final String setId;
  const SetDetailScreen({super.key, required this.setId});

  @override
  State<SetDetailScreen> createState() => _SetDetailScreenState();
}

class _SetDetailScreenState extends State<SetDetailScreen>{
  final _setsService    = SetsService();
  final _termCtrl       = TextEditingController();
  final _definitionCtrl = TextEditingController();

  StudySet? _studySet;
  List<Flashcard> _cards = [];
  int? _editingCardId;

  bool _isLoading = true;
  bool _isSaving  = false;
  String _error   = '';

  @override
  void initState(){
    super.initState();
    _loadData();
  }

  @override
  void dispose(){
    _termCtrl.dispose();
    _definitionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async{
    setState(() { _isLoading = true; _error = ''; });

    try{
      final results = await Future.wait([
        _setsService.getStudySetById(widget.setId),
        _setsService.getCardsForSet(widget.setId),
      ]);

      final setData  = results[0] as StudySet?;
      final cardData = results[1] as List<Flashcard>;

      if (!mounted) return;

      if (setData == null){
        setState(() { _error = 'Study set not found.'; _isLoading = false; });
        return;
      }

      await LocalStorageService.saveString(
          'last_set', jsonEncode(setData.toJson()));

      setState((){
        _studySet = setData;
        _cards    = cardData;
        _isLoading = false;
      });
    }
    catch (e){
      if (!mounted) return;
      setState((){
        _error = 'Failed to load this study set.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubmitCard() async{
    if (_termCtrl.text.trim().isEmpty || _definitionCtrl.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try{
      if (_editingCardId != null){
        await _setsService.updateCard(
          cardId: _editingCardId!,
          term: _termCtrl.text,
          definition: _definitionCtrl.text,
        );
      }
      else{
        await _setsService.createCard(
          setId: widget.setId,
          term: _termCtrl.text,
          definition: _definitionCtrl.text,
        );
      }

      _termCtrl.clear();
      _definitionCtrl.clear();
      setState(() { _editingCardId = null; _isSaving = false; });
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to save flashcard.'; _isSaving = false; });
    }
  }

  void _startEditing(Flashcard card){
    _termCtrl.text       = card.term;
    _definitionCtrl.text = card.definition;
    setState(() => _editingCardId = card.id);
  }

  void _cancelEdit(){
    _termCtrl.clear();
    _definitionCtrl.clear();
    setState(() => _editingCardId = null);
  }

  Future<void> _deleteCard(int cardId) async{
    final confirmed = await _showConfirmDialog('Delete this flashcard?');
    if (!confirmed) return;
    try {
      await _setsService.deleteCard(cardId);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to delete card.');
    }
  }

  Future<void> _deleteSet() async{
    if (_studySet == null) return;
    final confirmed = await _showConfirmDialog(
        'Delete the entire set "${_studySet!.title}"?\nThis cannot be undone.');
    if (!confirmed) return;
    try {
      await _setsService.deleteStudySet(_studySet!.id);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to delete study set.');
    }
  }

  Future<bool> _showConfirmDialog(String message) async{
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context){
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error.isNotEmpty && _studySet == null){
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Back to Dashboard',
                  onPressed: () => context.go('/dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSub),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          _studySet?.title ?? 'Set Detail',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete Set',
            onPressed: _deleteSet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.cardBorder),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            //set info and action buttons
            if (_studySet != null) ...[
              Text(
                _studySet!.description,
                style: const TextStyle(
                    color: AppColors.textSub, fontSize: 14),
              ),
              const SizedBox(height: 16),


              Row(
                children: [
                  _infoBadge('${_cards.length} cards'),
                ],
              ),
              const SizedBox(height: 14),

              //study/quiz buttons
              Row(
                children: [
                  Expanded(child: _actionButton(
                    icon: Icons.style_rounded,
                    label: 'Flashcards',
                    enabled: _cards.isNotEmpty,
                    onTap: () =>
                        context.go('/flashcards?setId=${widget.setId}'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _actionButton(
                    icon: Icons.quiz_rounded,
                    label: 'Quiz',
                    enabled: _cards.isNotEmpty,
                    onTap: () =>
                        context.go('/quiz?setId=${widget.setId}'),
                  )),
                ],
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 20),
            ],

            //add/edit card foprm
            Text(
              _editingCardId != null ? 'Edit Flashcard' : 'Add Flashcard',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  AppField(
                    label: 'Term',
                    placeholder: 'Front of the card',
                    controller: _termCtrl,
                  ),
                  AppField(
                    label: 'Definition',
                    placeholder: 'Back of the card',
                    controller: _definitionCtrl,
                    maxLines: 3,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: _editingCardId != null
                              ? (_isSaving ? 'Updating...' : 'Update Card')
                              : (_isSaving ? 'Adding...' : 'Add Card'),
                          isLoading: _isSaving,
                          onPressed: _handleSubmitCard,
                        ),
                      ),
                      if (_editingCardId != null) ...[
                        const SizedBox(width: 10),
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
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(_error,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            //cards list header
            Row(
              children: [
                const Text(
                  'Cards in this set',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_cards.length}',
                    style: const TextStyle(
                      color: AppColors.textLink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_cards.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: const Center(
                  child: Text(
                    'No flashcards yet.\nAdd the first one above.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSub, fontSize: 14),
                  ),
                ),
              )
            else
              ...List.generate(_cards.length, (i){
                final card = _cards[i];
                return _buildCardItem(card, i);
              }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(Flashcard card, int index){
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //number
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          //term/def
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.term,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.definition,
                  style: const TextStyle(
                      color: AppColors.textSub, fontSize: 13),
                ),
              ],
            ),
          ),

          // Edit / Delete
          Column(
            children: [
              GestureDetector(
                onTap: () => _startEditing(card),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                        color: AppColors.textLink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _deleteCard(card.id),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(String label){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x334F6FFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textLink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primarySoft : const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? const Color(0x334F6FFF)
                : const Color(0x1AFFFFFF),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled ? AppColors.textLink : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: enabled ? AppColors.textLink : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
