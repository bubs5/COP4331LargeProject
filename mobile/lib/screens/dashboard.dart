import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/studyset.dart';
import '../services/localstorage.dart';
import '../services/rewards_controller.dart';
import '../services/setsService.dart';
import '../widgets/setCard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _setsService = SetsService();

  List<StudySet> _studySets = [];
  StudySet? _lastSet;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final lastRaw = await LocalStorageService.getString('last_set');
      StudySet? last;
      if (lastRaw != null && lastRaw.isNotEmpty) {
        last = StudySet.fromJson(jsonDecode(lastRaw) as Map<String, dynamic>);
      }

      final sets = await _setsService.getStudySets();

      if (!mounted) return;
      setState(() {
        _studySets = sets;
        _lastSet = last;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load study sets.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openSet(StudySet set) async {
    await LocalStorageService.saveString('last_set', jsonEncode(set.toJson()));
    if (!mounted) return;
    context.go('/sets/${set.id}');
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
            title: Text(
              'StudyRewards',
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: colors.border),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.go('/sets/new'),
            backgroundColor: colors.primary,
            foregroundColor: colors.text,
            elevation: 0,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'New Set',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          body: RefreshIndicator(
            color: colors.primary,
            backgroundColor: colors.card,
            onRefresh: _loadData,
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(color: colors.primary),
            )
                : _errorMessage.isNotEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Color(0xFFF87171)),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              children: [
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick up where you left off.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSub,
                  ),
                ),
                const SizedBox(height: 24),
                _buildRecentCard(colors),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Sets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/sets/new'),
                      child: Text(
                        '+ Create New',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_studySets.isEmpty)
                  _buildEmptySets(colors)
                else ...[
                  ..._studySets.take(3).map(
                        (set) => SetCard(
                      studySet: set,
                      onTap: () => _openSet(set),
                    ),
                  ),
                  if (_studySets.length > 3)
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/sets/new'),
                        child: Text(
                          'View all ${_studySets.length} sets →',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentCard(dynamic colors) {
    return GestureDetector(
      onTap: _lastSet != null ? () => _openSet(_lastSet!) : null,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.history_rounded,
                color: colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECENT ACTIVITY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: colors.textSub,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_lastSet != null) ...[
                    Text(
                      _lastSet!.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      '${_lastSet!.cardCount} cards',
                      style: TextStyle(fontSize: 12, color: colors.textSub),
                    ),
                  ] else
                    Text(
                      'No recent activity',
                      style: TextStyle(fontSize: 14, color: colors.textSub),
                    ),
                ],
              ),
            ),
            if (_lastSet != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colors.textSub,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySets(dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.library_books_rounded,
              color: colors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No study sets yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + Create New to make your first set.',
            style: TextStyle(fontSize: 13, color: colors.textSub),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}