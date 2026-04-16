import 'dart:async';
import 'package:flutter/material.dart';

import '../models/rewards.dart';
import '../services/rewards_controller.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _message = '';
  bool _isError = false;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (rewardsController.loading) {
      rewardsController.init();
    }

    rewardsController.addListener(_listenForToast);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    rewardsController.removeListener(_listenForToast);
    _tabController.dispose();
    super.dispose();
  }

  void _listenForToast() {
    if (!mounted) return;
    final msg = rewardsController.toastMessage;
    if (msg.isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2200),
        ),
      );

    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2300), () {
      rewardsController.clearToast();
    });
  }

  Future<void> _handleUnlock(String themeId) async {
    setState(() {
      _message = '';
      _isError = false;
    });

    try {
      await rewardsController.unlockTheme(themeId);
      setState(() {
        _message = 'Theme unlocked! Tap Activate to use it.';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
        _isError = true;
      });
    }
  }

  Future<void> _handleActivate(String themeId) async {
    setState(() {
      _message = '';
      _isError = false;
    });

    try {
      await rewardsController.activateTheme(themeId);
      setState(() {
        _message = 'Theme activated!';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rewardsController,
      builder: (context, _) {
        final rewards = rewardsController.state;
        final theme = rewardsController.activeTheme;
        final colors = theme.colors;

        final level = (rewards.lifetimePoints ~/ 500) + 1;
        final levelProgress = (rewards.lifetimePoints % 500) / 500;
        final pointsToNext = 500 - (rewards.lifetimePoints % 500);

        return Scaffold(
          backgroundColor: colors.bg,
          appBar: AppBar(
            backgroundColor: colors.bg,
            title: Text(
              'Rewards',
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: colors.primary,
              labelColor: colors.text,
              unselectedLabelColor: colors.textSub,
              tabs: const [
                Tab(text: 'Theme Store'),
                Tab(text: 'How to Earn'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: rewardsController.loading
              ? Center(
            child: CircularProgressIndicator(color: colors.primary),
          )
              : Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Rewards',
                      style: TextStyle(
                        color: colors.textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${rewards.totalPoints} pts',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rewards.lifetimePoints} lifetime pts  •  ${rewards.streak}-day streak 🔥',
                      style: TextStyle(
                        color: colors.textSub,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            'Lv $level',
                            style: TextStyle(
                              color: colors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 8,
                                  value: levelProgress,
                                  backgroundColor:
                                  colors.border.withOpacity(0.35),
                                  valueColor: AlwaysStoppedAnimation(
                                    colors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$pointsToNext pts to Lv ${level + 1}',
                                style: TextStyle(
                                  color: colors.textSub,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isError
                          ? const Color(0x1AF87171)
                          : colors.primary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isError
                            ? const Color(0x4DF87171)
                            : colors.primary.withOpacity(0.30),
                      ),
                    ),
                    child: Text(
                      _message,
                      style: TextStyle(
                        color: _isError ? const Color(0xFFF87171) : colors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStoreTab(rewards, theme),
                    _buildEarnTab(theme),
                    _buildHistoryTab(rewards, theme),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoreTab(RewardsState rewards, RewardTheme activeTheme) {
    final colors = activeTheme.colors;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: rewardsController.themes.length,
      itemBuilder: (context, index) {
        final theme = rewardsController.themes[index];
        final isUnlocked = rewards.unlockedThemeIds.contains(theme.id);
        final isActive = rewards.activeThemeId == theme.id;
        final canAfford = rewards.totalPoints >= theme.cost;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? theme.colors.primary : colors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (theme.badge != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    theme.badge!,
                    style: TextStyle(
                      color: theme.colors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              Container(
                height: 84,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: theme.previewColors),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _dot(theme.colors.primary),
                        const SizedBox(width: 6),
                        _dot(theme.colors.accent),
                        const SizedBox(width: 6),
                        _dot(theme.colors.text),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      theme.name,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    theme.cost == 0 ? 'Free' : '${theme.cost} pts',
                    style: TextStyle(
                      color: (!canAfford && !isUnlocked)
                          ? const Color(0xFFF87171)
                          : colors.textSub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isActive)
                _statusPill('✓ Active', theme.colors.primary)
              else if (isUnlocked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleActivate(theme.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colors.primary,
                      foregroundColor: theme.colors.text,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Activate'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAfford ? () => _handleUnlock(theme.id) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford
                          ? theme.colors.primary
                          : colors.surface,
                      foregroundColor: theme.colors.text,
                      disabledBackgroundColor: colors.surface,
                      disabledForegroundColor: colors.textSub,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      canAfford
                          ? 'Unlock • ${theme.cost} pts'
                          : '🔒 ${theme.cost} pts',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarnTab(RewardTheme activeTheme) {
    final colors = activeTheme.colors;
    final events = rewardsController.rewardEvents.values.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text(
          'Complete activities to earn points and unlock rewards.',
          style: TextStyle(color: colors.textSub, fontSize: 14),
        ),
        const SizedBox(height: 16),
        ...events.map((event) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Text(event.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.label,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '+${event.points} pts',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.primary.withOpacity(0.25)),
          ),
          child: Text(
            '💡 Keep your streak going for bonus motivation. Perfect quiz scores are worth +75 pts.',
            style: TextStyle(
              color: colors.text,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(RewardsState rewards, RewardTheme activeTheme) {
    final colors = activeTheme.colors;

    if (rewards.history.isEmpty) {
      return Center(
        child: Text(
          'No activity yet. Start studying to earn points!',
          style: TextStyle(color: colors.textSub),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: rewards.history.length,
      itemBuilder: (context, index) {
        final entry = rewards.history[index];
        final icon = rewardsController.rewardEvents[entry.type]?.icon ?? '⭐';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(entry.date),
                      style: TextStyle(
                        color: colors.textSub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+${entry.points}',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;

    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final month = monthNames[dt.month - 1];
    final day = dt.day;
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $hour:$minute $suffix';
  }
}