import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/rewards_controller.dart';
import '../services/setsService.dart';
import '../widgets/appButton.dart';
import '../widgets/appField.dart';

class SetsScreen extends StatefulWidget {
  const SetsScreen({super.key});

  @override
  State<SetsScreen> createState() => _SetsScreenState();
}

class _SetsScreenState extends State<SetsScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _setsService = SetsService();

  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    setState(() {
      _error = '';
      _isLoading = true;
    });

    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      setState(() {
        _error = 'Please fill in both fields.';
        _isLoading = false;
      });
      return;
    }

    try {
      final newSet = await _setsService.createStudySet(
        title: _titleCtrl.text,
        description: _descCtrl.text,
      );

      await rewardsController.award('set_created');

      if (!mounted) return;
      context.go('/sets/${newSet.id}');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to create set.';
        _isLoading = false;
      });
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
              onPressed: () => context.go('/dashboard'),
            ),
            title: Text(
              'Create Set',
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'STUDY SETS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: colors.textSub,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create New Set',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppField(
                        label: 'Set Title',
                        placeholder: 'e.g. Math Chapter 5',
                        controller: _titleCtrl,
                      ),
                      AppField(
                        label: 'Description',
                        placeholder: 'What is this set for?',
                        controller: _descCtrl,
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
                      AppButton(
                        label: _isLoading ? 'Creating' : 'Create Set',
                        isLoading: _isLoading,
                        onPressed: _handleCreate,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}