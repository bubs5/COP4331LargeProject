import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/rewards.dart';
import 'localstorage.dart';

class RewardsService {
  static const String _storageKey = 'rewards_state';

  static const Map<String, RewardEvent> rewardEvents = {
    'daily_login': RewardEvent(
      type: 'daily_login',
      points: 10,
      label: 'Daily Login',
      icon: '☀️',
    ),
    'flashcard_session': RewardEvent(
      type: 'flashcard_session',
      points: 20,
      label: 'Flashcard Session',
      icon: '🃏',
    ),
    'cards_studied': RewardEvent(
      type: 'cards_studied',
      points: 5,
      label: 'Cards Studied',
      icon: '📖',
    ),
    'quiz_complete': RewardEvent(
      type: 'quiz_complete',
      points: 30,
      label: 'Quiz Completed',
      icon: '✅',
    ),
    'quiz_perfect': RewardEvent(
      type: 'quiz_perfect',
      points: 75,
      label: 'Perfect Quiz Score!',
      icon: '🏆',
    ),
    'set_created': RewardEvent(
      type: 'set_created',
      points: 15,
      label: 'New Set Created',
      icon: '✨',
    ),
    'study_streak': RewardEvent(
      type: 'study_streak',
      points: 50,
      label: 'Study Streak Bonus',
      icon: '🔥',
    ),
  };

  static const List<RewardTheme> themes = [
    RewardTheme(
      id: 'default',
      name: 'Midnight',
      cost: 0,
      unlocked: true,
      previewColors: [Color(0xFF080B1C), Color(0xFF4F6FFF)],
      colors: ThemeColorsData(
        bg: Color(0xFF080B1C),
        surface: Color(0xFF0C1022),
        card: Color(0xFF0F1428),
        primary: Color(0xFF4F6FFF),
        accent: Color(0xFF8B6FFF),
        text: Color(0xFFE8EAF6),
        textSub: Color(0xFF7B8CAD),
        border: Color(0x2D6378FF),
      ),
    ),
    RewardTheme(
      id: 'aurora',
      name: 'Aurora',
      cost: 150,
      unlocked: false,
      previewColors: [Color(0xFF0A2A1A), Color(0xFF00C97A)],
      colors: ThemeColorsData(
        bg: Color(0xFF060F0A),
        surface: Color(0xFF0A1810),
        card: Color(0xFF0D1F14),
        primary: Color(0xFF00C97A),
        accent: Color(0xFF00E5A0),
        text: Color(0xFFE0F5EC),
        textSub: Color(0xFF7AADA0),
        border: Color(0x2D00C97A),
      ),
    ),
    RewardTheme(
      id: 'crimson',
      name: 'Crimson',
      cost: 200,
      unlocked: false,
      previewColors: [Color(0xFF1A0508), Color(0xFFFF4466)],
      colors: ThemeColorsData(
        bg: Color(0xFF0E0205),
        surface: Color(0xFF160308),
        card: Color(0xFF1C040A),
        primary: Color(0xFFFF4466),
        accent: Color(0xFFFF6B8A),
        text: Color(0xFFF5E0E4),
        textSub: Color(0xFFAD7A85),
        border: Color(0x2DFF4466),
      ),
    ),
    RewardTheme(
      id: 'solar',
      name: 'Solar',
      cost: 250,
      unlocked: false,
      previewColors: [Color(0xFF1A1200), Color(0xFFFFAA00)],
      colors: ThemeColorsData(
        bg: Color(0xFF0E0A00),
        surface: Color(0xFF160F00),
        card: Color(0xFF1C1400),
        primary: Color(0xFFFFAA00),
        accent: Color(0xFFFFCC44),
        text: Color(0xFFF5F0E0),
        textSub: Color(0xFFADA070),
        border: Color(0x2DFFAA00),
      ),
    ),
    RewardTheme(
      id: 'frost',
      name: 'Frost',
      cost: 300,
      unlocked: false,
      previewColors: [Color(0xFF020D1A), Color(0xFF00BFFF)],
      colors: ThemeColorsData(
        bg: Color(0xFF010810),
        surface: Color(0xFF030E18),
        card: Color(0xFF051220),
        primary: Color(0xFF00BFFF),
        accent: Color(0xFF44D4FF),
        text: Color(0xFFDFF4FF),
        textSub: Color(0xFF6EA8C0),
        border: Color(0x2D00BFFF),
      ),
    ),
    RewardTheme(
      id: 'obsidian',
      name: 'Obsidian',
      cost: 400,
      unlocked: false,
      previewColors: [Color(0xFF0A0A0A), Color(0xFF888888)],
      colors: ThemeColorsData(
        bg: Color(0xFF050505),
        surface: Color(0xFF0A0A0A),
        card: Color(0xFF111111),
        primary: Color(0xFFAAAAAA),
        accent: Color(0xFFDDDDDD),
        text: Color(0xFFEFEFEF),
        textSub: Color(0xFF777777),
        border: Color(0x1FC8C8C8),
      ),
    ),
  ];

  Future<RewardsState> loadRewards() async {
    if (AppConfig.useMockData) {
      final raw = await LocalStorageService.getString(_storageKey);
      if (raw == null || raw.isEmpty) return RewardsState.initial();
      return RewardsState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }

    final userId = await _getUserId();
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/rewards/$userId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load rewards');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to load rewards');
    }

    return RewardsState.fromJson(
      Map<String, dynamic>.from(data['rewards'] ?? {}),
    );
  }

  Future<RewardsState> unlockTheme(RewardsState state, String themeId) async {
    final theme = themes.firstWhere(
          (t) => t.id == themeId,
      orElse: () => throw Exception('Theme not found'),
    );

    if (state.unlockedThemeIds.contains(themeId)) return state;
    if (state.totalPoints < theme.cost) {
      throw Exception('Not enough points.');
    }

    if (AppConfig.useMockData) {
      final updated = state.copyWith(
        totalPoints: state.totalPoints - theme.cost,
        unlockedThemeIds: [...state.unlockedThemeIds, themeId],
      );
      await _saveMock(updated);
      return updated;
    }

    final userId = await _getUserId();
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/rewards/$userId/unlock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'themeId': themeId}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Could not unlock theme');
    }

    return RewardsState.fromJson(
      Map<String, dynamic>.from(data['rewards'] ?? {}),
    );
  }

  Future<RewardsState> activateTheme(RewardsState state, String themeId) async {
    if (!state.unlockedThemeIds.contains(themeId)) {
      throw Exception('Theme is not unlocked.');
    }

    if (AppConfig.useMockData) {
      final updated = state.copyWith(activeThemeId: themeId);
      await _saveMock(updated);
      return updated;
    }

    final userId = await _getUserId();
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/rewards/$userId/activate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'themeId': themeId}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Could not activate theme');
    }

    return RewardsState.fromJson(
      Map<String, dynamic>.from(data['rewards'] ?? {}),
    );
  }

  Future<({RewardsState state, PointHistoryEntry entry})> awardPoints(
      RewardsState state,
      RewardEventType eventType, {
        int multiplier = 1,
      }) async {
    final event = rewardEvents[eventType];
    if (event == null) throw Exception('Unknown reward event');

    if (AppConfig.useMockData) {
      final earned = event.points * multiplier;
      final today = _dateOnly(DateTime.now());
      final yesterday = _dateOnly(
        DateTime.now().subtract(const Duration(days: 1)),
      );

      int newStreak = state.streak;
      if (state.lastActivityDate == yesterday) {
        newStreak += 1;
      } else if (state.lastActivityDate != today) {
        newStreak = 1;
      }

      final entry = PointHistoryEntry(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        type: eventType,
        points: earned,
        label: event.label,
        date: DateTime.now().toIso8601String(),
      );

      final updated = state.copyWith(
        totalPoints: state.totalPoints + earned,
        lifetimePoints: state.lifetimePoints + earned,
        history: [entry, ...state.history].take(50).toList(),
        streak: newStreak,
        lastActivityDate: today,
      );

      await _saveMock(updated);
      return (state: updated, entry: entry);
    }

    final userId = await _getUserId();
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/rewards/$userId/award'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'eventType': eventType,
        'multiplier': multiplier,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to award points');
    }

    final entry = PointHistoryEntry.fromJson(
      Map<String, dynamic>.from(data['entry'] ?? {}),
    );

    return (
    state: RewardsState.fromJson(
      Map<String, dynamic>.from(data['rewards'] ?? {}),
    ),
    entry: entry,
    );
  }

  RewardTheme getThemeById(String id) {
    return themes.firstWhere(
          (t) => t.id == id,
      orElse: () => themes.first,
    );
  }

  Future<void> _saveMock(RewardsState state) async {
    await LocalStorageService.saveString(_storageKey, jsonEncode(state.toJson()));
  }

  Future<String> _getUserId() async {
    final raw = await LocalStorageService.getString('user_data');
    if (raw == null || raw.isEmpty) {
      throw Exception('Not logged in');
    }
    final user = jsonDecode(raw) as Map<String, dynamic>;
    return user['id'].toString();
  }

  String _dateOnly(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }
}