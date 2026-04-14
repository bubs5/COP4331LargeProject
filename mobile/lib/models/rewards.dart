import 'dart:convert';

import 'package:flutter/material.dart';

enum RewardEventType {
  dailyLogin('daily_login'),
  flashcardSession('flashcard_session'),
  cardsStudied('cards_studied'),
  quizComplete('quiz_complete'),
  quizPerfect('quiz_perfect'),
  setCreated('set_created'),
  studyStreak('study_streak');

  const RewardEventType(this.value);
  final String value;

  static RewardEventType fromValue(String value) {
    return RewardEventType.values.firstWhere(
      (event) => event.value == value,
      orElse: () => RewardEventType.dailyLogin,
    );
  }
}

class RewardEvent {
  const RewardEvent({
    required this.type,
    required this.points,
    required this.label,
    required this.icon,
  });

  final RewardEventType type;
  final int points;
  final String label;
  final String icon;
}

class ThemeColors {
  const ThemeColors({
    required this.bg,
    required this.surface,
    required this.card,
    required this.primary,
    required this.accent,
    required this.text,
    required this.textSub,
    required this.border,
    required this.gradient,
  });

  final String bg;
  final String surface;
  final String card;
  final String primary;
  final String accent;
  final String text;
  final String textSub;
  final String border;
  final String gradient;

  Color get bgColor => colorFromHex(bg);
  Color get surfaceColor => colorFromHex(surface);
  Color get cardColor => colorFromHex(card);
  Color get primaryColor => colorFromHex(primary);
  Color get accentColor => colorFromHex(accent);
  Color get textColor => colorFromHex(text);
  Color get textSubColor => colorFromHex(textSub);
  Color get borderColor => colorFromCss(border);
  List<Color> get gradientColors => gradientToColors(gradient);
}

class RewardTheme {
  const RewardTheme({
    required this.id,
    required this.name,
    required this.cost,
    required this.unlocked,
    required this.colors,
    required this.preview,
    this.badge,
  });

  final String id;
  final String name;
  final int cost;
  final bool unlocked;
  final ThemeColors colors;
  final String preview;
  final String? badge;
}

class PointHistoryEntry {
  const PointHistoryEntry({
    required this.id,
    required this.type,
    required this.points,
    required this.label,
    required this.date,
  });

  final String id;
  final RewardEventType type;
  final int points;
  final String label;
  final String date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'points': points,
        'label': label,
        'date': date,
      };

  factory PointHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PointHistoryEntry(
      id: (json['_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch)
          .toString(),
      type: RewardEventType.fromValue((json['type'] ?? '').toString()),
      points: (json['points'] as num? ?? 0).toInt(),
      label: (json['label'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
    );
  }
}

class RewardsState {
  const RewardsState({
    required this.totalPoints,
    required this.lifetimePoints,
    required this.activeThemeId,
    required this.unlockedThemeIds,
    required this.history,
    required this.streak,
    required this.lastActivityDate,
  });

  final int totalPoints;
  final int lifetimePoints;
  final String activeThemeId;
  final List<String> unlockedThemeIds;
  final List<PointHistoryEntry> history;
  final int streak;
  final String lastActivityDate;

  static const RewardsState defaults = RewardsState(
    totalPoints: 0,
    lifetimePoints: 0,
    activeThemeId: 'default',
    unlockedThemeIds: ['default'],
    history: [],
    streak: 0,
    lastActivityDate: '',
  );

  RewardsState copyWith({
    int? totalPoints,
    int? lifetimePoints,
    String? activeThemeId,
    List<String>? unlockedThemeIds,
    List<PointHistoryEntry>? history,
    int? streak,
    String? lastActivityDate,
  }) {
    return RewardsState(
      totalPoints: totalPoints ?? this.totalPoints,
      lifetimePoints: lifetimePoints ?? this.lifetimePoints,
      activeThemeId: activeThemeId ?? this.activeThemeId,
      unlockedThemeIds: unlockedThemeIds ?? this.unlockedThemeIds,
      history: history ?? this.history,
      streak: streak ?? this.streak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalPoints': totalPoints,
        'lifetimePoints': lifetimePoints,
        'activeThemeId': activeThemeId,
        'unlockedThemeIds': unlockedThemeIds,
        'history': history.map((entry) => entry.toJson()).toList(),
        'streak': streak,
        'lastActivityDate': lastActivityDate,
      };

  factory RewardsState.fromJson(Map<String, dynamic> json) {
    return RewardsState(
      totalPoints: (json['totalPoints'] as num? ?? 0).toInt(),
      lifetimePoints: (json['lifetimePoints'] as num? ?? 0).toInt(),
      activeThemeId: (json['activeThemeId'] ?? 'default').toString(),
      unlockedThemeIds: ((json['unlockedThemeIds'] as List<dynamic>? ??
              const <dynamic>['default']))
          .map((id) => id.toString())
          .toList(),
      history: (json['history'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .map(PointHistoryEntry.fromJson)
          .toList(),
      streak: (json['streak'] as num? ?? 0).toInt(),
      lastActivityDate: (json['lastActivityDate'] ?? '').toString(),
    );
  }

  static RewardsState fromStorage(String raw) {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return RewardsState.defaults.merge(RewardsState.fromJson(decoded));
    } catch (_) {
      return RewardsState.defaults;
    }
  }

  RewardsState merge(RewardsState other) {
    return copyWith(
      totalPoints: other.totalPoints,
      lifetimePoints: other.lifetimePoints,
      activeThemeId: other.activeThemeId,
      unlockedThemeIds: other.unlockedThemeIds,
      history: other.history,
      streak: other.streak,
      lastActivityDate: other.lastActivityDate,
    );
  }
}

String isoDateOnly(DateTime dateTime) {
  return dateTime.toIso8601String().split('T').first;
}

Color colorFromHex(String hex) {
  final normalized = hex.replaceAll('#', '').trim();
  final withAlpha = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.parse(withAlpha, radix: 16));
}

Color colorFromCss(String css) {
  final trimmed = css.trim();
  if (trimmed.startsWith('#')) {
    return colorFromHex(trimmed);
  }

  final rgbaMatch = RegExp(
    r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)',
  ).firstMatch(trimmed);

  if (rgbaMatch != null) {
    final r = int.parse(rgbaMatch.group(1)!);
    final g = int.parse(rgbaMatch.group(2)!);
    final b = int.parse(rgbaMatch.group(3)!);
    final a = (double.parse(rgbaMatch.group(4)!) * 255).round();
    return Color.fromARGB(a, r, g, b);
  }

  return const Color(0x2D6378FF);
}

List<Color> gradientToColors(String gradient) {
  final hexMatches = RegExp(r'#[0-9a-fA-F]{6}').allMatches(gradient).toList();
  if (hexMatches.length >= 2) {
    return [
      colorFromHex(hexMatches.first.group(0)!),
      colorFromHex(hexMatches.last.group(0)!),
    ];
  }
  return const [Color(0xFF4F6FFF), Color(0xFF7C3AED)];
}

String formatHistoryDate(String isoString) {
  final dateTime = DateTime.tryParse(isoString);
  if (dateTime == null) return '';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final month = months[dateTime.month - 1];
  final day = dateTime.day.toString();
  final hour24 = dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;

  return '$month $day, $hour12:$minute $period';
}
