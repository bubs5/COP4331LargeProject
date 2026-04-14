import 'package:flutter/material.dart';

typedef RewardEventType = String;

class RewardEvent {
  final RewardEventType type;
  final int points;
  final String label;
  final String icon;

  const RewardEvent({
    required this.type,
    required this.points,
    required this.label,
    required this.icon,
  });
}

class ThemeColorsData {
  final Color bg;
  final Color surface;
  final Color card;
  final Color primary;
  final Color accent;
  final Color text;
  final Color textSub;
  final Color border;

  const ThemeColorsData({
    required this.bg,
    required this.surface,
    required this.card,
    required this.primary,
    required this.accent,
    required this.text,
    required this.textSub,
    required this.border,
  });
}

class RewardTheme {
  final String id;
  final String name;
  final int cost;
  final bool unlocked;
  final List<Color> previewColors;
  final ThemeColorsData colors;
  final String? badge;

  const RewardTheme({
    required this.id,
    required this.name,
    required this.cost,
    required this.unlocked,
    required this.previewColors,
    required this.colors,
    this.badge,
  });
}

class PointHistoryEntry {
  final String id;
  final RewardEventType type;
  final int points;
  final String label;
  final String date;

  const PointHistoryEntry({
    required this.id,
    required this.type,
    required this.points,
    required this.label,
    required this.date,
  });

  factory PointHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PointHistoryEntry(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      points: (json['points'] ?? 0) as int,
      label: (json['label'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'points': points,
      'label': label,
      'date': date,
    };
  }
}

class RewardsState {
  final int totalPoints;
  final int lifetimePoints;
  final String activeThemeId;
  final List<String> unlockedThemeIds;
  final List<PointHistoryEntry> history;
  final int streak;
  final String lastActivityDate;

  const RewardsState({
    required this.totalPoints,
    required this.lifetimePoints,
    required this.activeThemeId,
    required this.unlockedThemeIds,
    required this.history,
    required this.streak,
    required this.lastActivityDate,
  });

  factory RewardsState.initial() {
    return const RewardsState(
      totalPoints: 0,
      lifetimePoints: 0,
      activeThemeId: 'default',
      unlockedThemeIds: ['default'],
      history: [],
      streak: 0,
      lastActivityDate: '',
    );
  }

  factory RewardsState.fromJson(Map<String, dynamic> json) {
    return RewardsState(
      totalPoints: (json['totalPoints'] ?? 0) as int,
      lifetimePoints: (json['lifetimePoints'] ?? 0) as int,
      activeThemeId: (json['activeThemeId'] ?? 'default').toString(),
      unlockedThemeIds: ((json['unlockedThemeIds'] ?? ['default']) as List)
          .map((e) => e.toString())
          .toList(),
      history: ((json['history'] ?? []) as List)
          .map((e) => PointHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      streak: (json['streak'] ?? 0) as int,
      lastActivityDate: (json['lastActivityDate'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPoints': totalPoints,
      'lifetimePoints': lifetimePoints,
      'activeThemeId': activeThemeId,
      'unlockedThemeIds': unlockedThemeIds,
      'history': history.map((e) => e.toJson()).toList(),
      'streak': streak,
      'lastActivityDate': lastActivityDate,
    };
  }

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
}