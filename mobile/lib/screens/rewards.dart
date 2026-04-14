import 'package:flutter/material.dart';

import '../models/rewards.dart';
import '../services/rewardsProvider.dart';

enum _RewardsTab { store, earn, history }

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  static const int _pointsPerLevel = 500;
  _RewardsTab _tab = _RewardsTab.store;
  String _error = '';
  String _success = '';

  @override
  Widget build(BuildContext context) {
    final provider = RewardsScope.of(context);
    final rewards = provider.rewards;
    final theme = provider.activeTheme;

    final level = (rewards.lifetimePoints / _pointsPerLevel).floor() + 1;
    final progress = (rewards.lifetimePoints % _pointsPerLevel) / _pointsPerLevel;
    final pointsToNext = _pointsPerLevel - (rewards.lifetimePoints % _pointsPerLevel);

    return Scaffold(
      backgroundColor: theme.colors.bgColor,
      appBar: AppBar(
        title: const Text('Rewards'),
        backgroundColor: theme.colors.bgColor,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colors.borderColor),
              gradient: RadialGradient(
                center: const Alignment(-0.3, -1),
                radius: 1.6,
                colors: [
                  theme.colors.primaryColor.withOpacity(0.2),
                  theme.colors.surfaceColor.withOpacity(0.9),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 20, 0.5),
                  blurRadius: 70,
                  offset: Offset(0, 30),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Rewards',
                        style: TextStyle(
                          color: theme.colors.textSubColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${rewards.totalPoints} pts',
                        style: TextStyle(
                          color: theme.colors.textColor,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.6,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${rewards.lifetimePoints} lifetime pts · ${rewards.streak}-day streak🔥',
                        style: TextStyle(
                          color: theme.colors.textSubColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Lv $level',
                        style: TextStyle(
                          color: theme.colors.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          color: theme.colors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$pointsToNext pts to Lv ${level + 1}',
                        style: TextStyle(
                          color: theme.colors.textSubColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTab(theme, _RewardsTab.store, 'Theme Store'),
              _buildTab(theme, _RewardsTab.earn, 'How to Earn'),
              _buildTab(theme, _RewardsTab.history, 'History'),
            ],
          ),
          const SizedBox(height: 18),
          if (_error.isNotEmpty) _message(theme, _error, true),
          if (_success.isNotEmpty) _message(theme, _success, false),
          if (_tab == _RewardsTab.store) _buildStore(provider),
          if (_tab == _RewardsTab.earn) _buildEarn(provider),
          if (_tab == _RewardsTab.history) _buildHistory(provider),
        ],
      ),
    );
  }

  Widget _buildTab(RewardTheme theme, _RewardsTab tab, String label) {
    final active = _tab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tab = tab;
          _error = '';
          _success = '';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: active
              ? null
              : Border.all(
                  color: theme.colors.borderColor,
                ),
          gradient: active
              ? LinearGradient(colors: theme.colors.gradientColors)
              : null,
          color: active ? null : Colors.transparent,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: theme.colors.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : theme.colors.textSubColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _message(RewardTheme theme, String message, bool isError) {
    final baseColor = isError ? const Color(0xFFF87171) : const Color(0xFF86EFAC);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: baseColor.withOpacity(isError ? 0.12 : 0.1),
        border: Border.all(color: baseColor.withOpacity(0.28)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: baseColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStore(RewardsProvider provider) {
    final rewards = provider.rewards;
    final theme = provider.activeTheme;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: provider.themes.map((storeTheme) {
        final isUnlocked = rewards.unlockedThemeIds.contains(storeTheme.id);
        final isActive = rewards.activeThemeId == storeTheme.id;
        final canAfford = rewards.totalPoints >= storeTheme.cost;

        return Container(
          width: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: storeTheme.colors.surfaceColor.withOpacity(0.88),
            border: Border.all(
              color: isActive
                  ? theme.colors.primaryColor
                  : theme.colors.borderColor,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colors.primaryColor.withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              if (storeTheme.badge != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(colors: theme.colors.gradientColors),
                    ),
                    child: Text(
                      storeTheme.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 90,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                      gradient: LinearGradient(
                        colors: gradientToColors(storeTheme.preview),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _dot(storeTheme.colors.primaryColor),
                          const SizedBox(width: 6),
                          _dot(storeTheme.colors.accentColor),
                          const SizedBox(width: 6),
                          _dot(storeTheme.colors.textColor),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          storeTheme.name,
                          style: TextStyle(
                            color: theme.colors.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          storeTheme.cost == 0
                              ? 'Free'
                              : '${storeTheme.cost} pts',
                          style: TextStyle(
                            color: storeTheme.cost == 0
                                ? const Color(0xFF86EFAC)
                                : (!canAfford && !isUnlocked)
                                    ? theme.colors.textSubColor
                                    : theme.colors.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                    child: _buildThemeAction(
                      provider,
                      storeTheme,
                      isUnlocked,
                      isActive,
                      canAfford,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildThemeAction(
    RewardsProvider provider,
    RewardTheme storeTheme,
    bool isUnlocked,
    bool isActive,
    bool canAfford,
  ) {
    final theme = provider.activeTheme;

    if (isActive) {
      return Center(
        child: Text(
          '✓ Active',
          style: TextStyle(
            color: theme.colors.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (isUnlocked) {
      return _actionButton(
        label: 'Activate',
        gradient: LinearGradient(colors: theme.colors.gradientColors),
        textColor: Colors.white,
        onTap: () async {
          setState(() {
            _error = '';
            _success = '';
          });
          try {
            await provider.activate(storeTheme.id);
            setState(() => _success = 'Theme activated!');
          } catch (error) {
            setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
          }
        },
      );
    }

    return _actionButton(
      label: canAfford
          ? 'Unlock · ${storeTheme.cost}pts'
          : '🔒 ${storeTheme.cost}pts',
      borderColor: theme.colors.primaryColor.withOpacity(0.3),
      backgroundColor: theme.colors.primaryColor.withOpacity(0.12),
      textColor: canAfford ? theme.colors.primaryColor : theme.colors.textSubColor,
      onTap: canAfford
          ? () async {
              setState(() {
                _error = '';
                _success = '';
              });
              try {
                await provider.unlock(storeTheme.id);
                setState(() => _success = 'Theme unlocked! Click Activate to use it.');
              } catch (error) {
                setState(() {
                  _error = error.toString().replaceFirst('Exception: ', '');
                });
              }
            }
          : null,
    );
  }

  Widget _actionButton({
    required String label,
    Gradient? gradient,
    Color? backgroundColor,
    Color? borderColor,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: gradient,
          color: gradient == null ? backgroundColor : null,
          border: gradient == null && borderColor != null
              ? Border.all(color: borderColor)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEarn(RewardsProvider provider) {
    final theme = provider.activeTheme;
    final perfectQuizPoints =
        provider.rewardEvents[RewardEventType.quizPerfect]?.points ?? 75;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete activities to earn points and unlock rewards.',
          style: TextStyle(color: theme.colors.textSubColor, fontSize: 15),
        ),
        const SizedBox(height: 20),
        ...provider.rewardEvents.values.map(
          (event) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.colors.cardColor.withOpacity(0.76),
              border: Border.all(color: theme.colors.borderColor),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    event.icon,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 21),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    event.label,
                    style: TextStyle(
                      color: theme.colors.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '+${event.points} pts',
                  style: TextStyle(
                    color: theme.colors.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: theme.colors.primaryColor.withOpacity(0.07),
            border: Border.all(color: theme.colors.primaryColor.withOpacity(0.2)),
          ),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: theme.colors.textSubColor,
                fontSize: 14,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: '💡  Keep your daily study streak going. A perfect quiz score gives ',
                ),
                TextSpan(
                  text: '+$perfectQuizPoints pts',
                  style: TextStyle(
                    color: theme.colors.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' instead of the usual 30!'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistory(RewardsProvider provider) {
    final rewards = provider.rewards;
    final theme = provider.activeTheme;

    if (rewards.history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No activity yet. Start studying to earn points!',
            style: TextStyle(color: theme.colors.textSubColor),
          ),
        ),
      );
    }

    return Column(
      children: rewards.history.map((entry) {
        final icon = provider.rewardEvents[entry.type]?.icon ?? '⭐';
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: theme.colors.cardColor.withOpacity(0.76),
            border: Border.all(color: theme.colors.borderColor),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  icon,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: TextStyle(
                        color: theme.colors.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formatHistoryDate(entry.date),
                      style: TextStyle(
                        color: theme.colors.textSubColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '+',
                style: TextStyle(
                  color: Color(0xFF86EFAC),
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${entry.points}',
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
