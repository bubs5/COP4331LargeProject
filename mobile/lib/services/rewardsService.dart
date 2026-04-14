import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/rewards.dart';
import 'authService.dart';
import 'localstorage.dart';

class AwardPointsResult {
  const AwardPointsResult({required this.state, required this.entry});

  final RewardsState state;
  final PointHistoryEntry entry;
}

class RewardsService {
  static const String _storageKey = 'rewards_state';

  static const Map<RewardEventType, RewardEvent> rewardEvents = {
    RewardEventType.dailyLogin: RewardEvent(
      type: RewardEventType.dailyLogin,
      points: 10,
      label: 'Daily Login',
      icon: '☀️',
    ),
    RewardEventType.flashcardSession: RewardEvent(
      type: RewardEventType.flashcardSession,
      points: 20,
      label: 'Flashcard Session',
      icon: '🃏',
    ),
    RewardEventType.cardsStudied: RewardEvent(
      type: RewardEventType.cardsStudied,
      points: 5,
      label: 'Cards Studied',
      icon: '📖',
    ),
    RewardEventType.quizComplete: RewardEvent(
      type: RewardEventType.quizComplete,
      points: 30,
      label: 'Quiz Completed',
      icon: '✅',
    ),
    RewardEventType.quizPerfect: RewardEvent(
      type: RewardEventType.quizPerfect,
      points: 75,
      label: 'Perfect Quiz Score!',
      icon: '🏆',
    ),
    RewardEventType.setCreated: RewardEvent(
      type: RewardEventType.setCreated,
      points: 15,
      label: 'New Set Created',
      icon: '✨',
    ),
    RewardEventType.studyStreak: RewardEvent(
      type: RewardEventType.studyStreak,
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
      preview: 'linear-gradient(135deg, #080B1C, #4F6FFF)',
      colors: ThemeColors(
        bg: '#080B1C',
        surface: '#0C1022',
        card: '#0F1428',
        primary: '#4F6FFF',
        accent: '#8B6FFF',
        text: '#E8EAF6',
        textSub: '#7B8CAD',
        border: 'rgba(99,120,255,0.18)',
        gradient: 'linear-gradient(135deg, #4F6FFF, #7C3AED)',
      ),
    ),
    RewardTheme(
      id: 'aurora',
      name: 'Aurora',
      cost: 150,
      unlocked: false,
      preview: 'linear-gradient(135deg, #0a2a1a, #00c97a)',
      colors: ThemeColors(
        bg: '#060F0A',
        surface: '#0A1810',
        card: '#0D1F14',
        primary: '#00C97A',
        accent: '#00E5A0',
        text: '#E0F5EC',
        textSub: '#7AADA0',
        border: 'rgba(0,201,122,0.18)',
        gradient: 'linear-gradient(135deg, #00C97A, #0068A4)',
      ),
    ),
    RewardTheme(
      id: 'crimson',
      name: 'Crimson',
      cost: 200,
      unlocked: false,
      preview: 'linear-gradient(135deg, #1a0508, #FF4466)',
      colors: ThemeColors(
        bg: '#0E0205',
        surface: '#160308',
        card: '#1C040A',
        primary: '#FF4466',
        accent: '#FF6B8A',
        text: '#F5E0E4',
        textSub: '#AD7A85',
        border: 'rgba(255,68,102,0.18)',
        gradient: 'linear-gradient(135deg, #FF4466, #CC2244)',
      ),
    ),
    RewardTheme(
      id: 'solar',
      name: 'Solar',
      cost: 250,
      unlocked: false,
      preview: 'linear-gradient(135deg, #1a1200, #FFAA00)',
      colors: ThemeColors(
        bg: '#0E0A00',
        surface: '#160F00',
        card: '#1C1400',
        primary: '#FFAA00',
        accent: '#FFCC44',
        text: '#F5F0E0',
        textSub: '#ADA070',
        border: 'rgba(255,170,0,0.18)',
        gradient: 'linear-gradient(135deg, #FFAA00, #FF6600)',
      ),
    ),
    RewardTheme(
      id: 'frost',
      name: 'Frost',
      cost: 300,
      unlocked: false,
      preview: 'linear-gradient(135deg, #020D1A, #00BFFF)',
      colors: ThemeColors(
        bg: '#010810',
        surface: '#030E18',
        card: '#051220',
        primary: '#00BFFF',
        accent: '#44D4FF',
        text: '#DFF4FF',
        textSub: '#6EA8C0',
        border: 'rgba(0,191,255,0.18)',
        gradient: 'linear-gradient(135deg, #00BFFF, #0050AA)',
      ),
    ),
    RewardTheme(
      id: 'obsidian',
      name: 'Obsidian',
      cost: 400,
      unlocked: false,
      preview: 'linear-gradient(135deg, #0a0a0a, #888)',
      colors: ThemeColors(
        bg: '#050505',
        surface: '#0A0A0A',
        card: '#111111',
        primary: '#AAAAAA',
        accent: '#DDDDDD',
        text: '#EFEFEF',
        textSub: '#777777',
        border: 'rgba(200,200,200,0.12)',
        gradient: 'linear-gradient(135deg, #888, #444)',
      ),
    ),
  ];

  RewardTheme getThemeById(String id) {
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }

  Future<RewardsState> loadRewards() async {
    if (AppConfig.useMockData) {
      final raw = await LocalStorageService.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        return RewardsState.defaults;
      }
      return RewardsState.fromStorage(raw);
    }

    final userId = await _getUserId();
    final response = await http.get(Uri.parse('${AppConfig.baseUrl}/rewards/$userId'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['success'] != true) {
      throw Exception((data['error'] ?? 'Failed to load rewards').toString());
    }

    return _normalizeState(data['rewards'] as Map<String, dynamic>? ?? const {});
  }

  Future<AwardPointsResult> awardPoints(
    RewardsState state,
    RewardEventType eventType, {
    double multiplier = 1,
  }) async {
    if (AppConfig.useMockData) {
      final event = rewardEvents[eventType]!;
      final earned = (event.points * multiplier).round();
      final now = DateTime.now();
      final today = isoDateOnly(now);
      final yesterday = isoDateOnly(now.subtract(const Duration(days: 1)));

      var newStreak = state.streak;
      if (state.lastActivityDate == yesterday) {
        newStreak += 1;
      } else if (state.lastActivityDate != today) {
        newStreak = 1;
      }

      final entry = PointHistoryEntry(
        id: _generateEntryId(now, state, eventType),
        type: eventType,
        points: earned,
        label: event.label,
        date: now.toIso8601String(),
      );

      final updated = state.copyWith(
        totalPoints: state.totalPoints + earned,
        lifetimePoints: state.lifetimePoints + earned,
        history: [entry, ...state.history].take(50).toList(),
        streak: newStreak,
        lastActivityDate: today,
      );

      await saveRewards(updated);
      return AwardPointsResult(state: updated, entry: entry);
    }

    final userId = await _getUserId();
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/rewards/$userId/award'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'eventType': eventType.value,
        'multiplier': multiplier,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception((data['error'] ?? 'Failed to award points').toString());
    }

    final entry = PointHistoryEntry.fromJson(
      data['entry'] as Map<String, dynamic>? ?? const {},
    );

    return AwardPointsResult(
      state: _normalizeState(data['rewards'] as Map<String, dynamic>? ?? const {}),
      entry: entry,
    );
  }

  Future<RewardsState> unlockTheme(RewardsState state, String themeId) async {
    if (AppConfig.useMockData) {
      final theme = getThemeById(themeId);

      if (state.unlockedThemeIds.contains(themeId)) {
        throw Exception('Already unlocked');
      }
      if (state.totalPoints < theme.cost) {
        throw Exception('Not enough points');
      }

      final updated = state.copyWith(
        totalPoints: state.totalPoints - theme.cost,
        unlockedThemeIds: [...state.unlockedThemeIds, themeId],
      );

      await saveRewards(updated);
      return updated;
    }

    final userId = await _getUserId();
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/rewards/$userId/unlock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'themeId': themeId}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception((data['error'] ?? 'Could not unlock theme').toString());
    }

    return _normalizeState(data['rewards'] as Map<String, dynamic>? ?? const {});
  }

  Future<RewardsState> setActiveTheme(RewardsState state, String themeId) async {
    if (AppConfig.useMockData) {
      if (!state.unlockedThemeIds.contains(themeId)) {
        throw Exception('Theme not unlocked');
      }

      final updated = state.copyWith(activeThemeId: themeId);
      await saveRewards(updated);
      return updated;
    }

    final userId = await _getUserId();
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/rewards/$userId/activate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'themeId': themeId}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception((data['error'] ?? 'Could not activate theme').toString());
    }

    return _normalizeState(data['rewards'] as Map<String, dynamic>? ?? const {});
  }

  Future<void> saveRewards(RewardsState state) async {
    if (!AppConfig.useMockData) {
      return;
    }

    await LocalStorageService.saveString(_storageKey, jsonEncode(state.toJson()));
  }

  RewardsState _normalizeState(Map<String, dynamic> doc) {
    return RewardsState(
      totalPoints: (doc['totalPoints'] as num? ?? 0).toInt(),
      lifetimePoints: (doc['lifetimePoints'] as num? ?? 0).toInt(),
      activeThemeId: (doc['activeThemeId'] ?? 'default').toString(),
      unlockedThemeIds: ((doc['unlockedThemeIds'] as List<dynamic>? ??
              const <dynamic>['default']))
          .map((id) => id.toString())
          .toList(),
      history: (doc['history'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .map(PointHistoryEntry.fromJson)
          .toList(),
      streak: (doc['streak'] as num? ?? 0).toInt(),
      lastActivityDate: (doc['lastActivityDate'] ?? '').toString(),
    );
  }

  Future<String> _getUserId() async {
    final user = await AuthService().getUser();
    final id = user?['id'];
    if (id == null) {
      throw Exception('Not logged in');
    }
    return id.toString();
  }

  String _generateEntryId(
    DateTime now,
    RewardsState state,
    RewardEventType eventType,
  ) {
    return '${now.microsecondsSinceEpoch}-${eventType.value}-${now.millisecondsSinceEpoch ^ state.totalPoints}';
  }
}
