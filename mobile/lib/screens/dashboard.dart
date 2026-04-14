import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/rewards.dart';
import '../models/studyset.dart';
import '../services/setsService.dart';
import '../services/localstorage.dart';
import '../services/rewardsProvider.dart';
import '../widgets/setCard.dart';

class DashboardScreen extends StatefulWidget{
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>{
  final _setsService = SetsService();

  List<StudySet> _studySets = [];
  StudySet? _lastSet;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _dailyLoginAwardChecked = false;

  @override
  void initState(){
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async{
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try{
      final lastRaw = await LocalStorageService.getString('last_set');
      StudySet? last;
      if (lastRaw != null && lastRaw.isNotEmpty){
        last = StudySet.fromJson(jsonDecode(lastRaw) as Map<String, dynamic>);
      }

      final sets = await _setsService.getStudySets();

      if (!mounted) return;
      setState((){
        _studySets = sets;
        _lastSet = last;
        _isLoading = false;
      });
    }
    catch (e){
      if (!mounted) return;
      setState((){
        _errorMessage = 'Failed to load study sets.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openSet(StudySet set) async{
    await LocalStorageService.saveString('last_set', jsonEncode(set.toJson()));
    if (!mounted) return;
    context.go('/sets/${set.id}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dailyLoginAwardChecked) return;
    final rewards = RewardsScope.of(context);
    if (rewards.loading) return;

    _dailyLoginAwardChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final today = isoDateOnly(DateTime.now());
      if (rewards.rewards.lastActivityDate != today) {
        await rewards.award(RewardEventType.dailyLogin);
      }
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'StudyRewards',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.go('/rewards'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '⭐ ${RewardsScope.of(context).rewards.totalPoints} pts',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.cardBorder),
        ),
      ),
      floatingActionButton: _buildFab(),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
            : _errorMessage.isNotEmpty
            ? _buildError()
            : _buildBody(),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => context.go('/sets/new'),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Set',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildError(){
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _errorMessage,
          style: const TextStyle(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        //welcome
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pick up where you left off.',
          style: TextStyle(fontSize: 14, color: AppColors.textSub),
        ),
        const SizedBox(height: 24),

        //recent activity card
        _buildRecentCard(),
        const SizedBox(height: 28),

        //sets header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Sets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/sets/new'),
              child: const Text(
                '+ Create New',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textLink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_studySets.isEmpty)
          _buildEmptySets()
        else ...[
          ...(_studySets.take(3).map((set) => SetCard(
            studySet: set,
            onTap: () => _openSet(set),
          ))),
          if (_studySets.length > 3)
            Center(
              child: GestureDetector(
                onTap: () => context.go('/sets/new'),
                child: Text(
                  'View all ${_studySets.length} sets →',
                  style: const TextStyle(
                    color: AppColors.textLink,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildRecentCard(){
    return GestureDetector(
      onTap: _lastSet != null ? () => _openSet(_lastSet!) : null,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x334F6FFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x334F6FFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppColors.textLink,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECENT ACTIVITY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_lastSet != null) ...[
                    Text(
                      _lastSet!.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_lastSet!.cardCount} cards',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSub),
                    ),
                  ] else
                    const Text(
                      'No recent activity',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSub),
                    ),
                ],
              ),
            ),
            if (_lastSet != null)
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySets(){
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),

          ),
          const SizedBox(height: 16),
          const Text(
            'No study sets yet',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + Create New to make your first set.',
            style: TextStyle(fontSize: 13, color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
