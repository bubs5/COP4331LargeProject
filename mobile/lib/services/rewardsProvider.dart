import 'dart:async';

import 'package:flutter/material.dart';

import '../models/rewards.dart';
import 'rewardsService.dart';

class PointToastData {
  const PointToastData({
    required this.id,
    required this.points,
    required this.label,
    required this.icon,
  });

  final String id;
  final int points;
  final String label;
  final String icon;
}

class RewardsProvider extends ChangeNotifier {
  RewardsProvider({RewardsService? service}) : _service = service ?? RewardsService() {
    load();
  }

  final RewardsService _service;

  RewardsState _rewards = RewardsState.defaults;
  bool _loading = true;
  PointToastData? _toast;
  Timer? _toastTimer;
  bool _isDisposed = false;

  RewardsState get rewards => _rewards;
  bool get loading => _loading;
  PointToastData? get toast => _toast;
  RewardTheme get activeTheme => _service.getThemeById(_rewards.activeThemeId);
  List<RewardTheme> get themes => RewardsService.themes;
  Map<RewardEventType, RewardEvent> get rewardEvents => RewardsService.rewardEvents;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      _rewards = await _service.loadRewards();
    } catch (_) {
      _rewards = RewardsState.defaults;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<PointHistoryEntry> award(RewardEventType type, {double multiplier = 1}) async {
    final result = await _service.awardPoints(_rewards, type, multiplier: multiplier);
    _rewards = result.state;

    final event = rewardEvents[type]!;
    _toast = PointToastData(
      id: result.entry.id,
      points: result.entry.points,
      label: result.entry.label,
      icon: event.icon,
    );

    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2800), () {
      if (_isDisposed) return;
      _toast = null;
      notifyListeners();
    });

    notifyListeners();
    return result.entry;
  }

  Future<void> unlock(String themeId) async {
    _rewards = await _service.unlockTheme(_rewards, themeId);
    notifyListeners();
  }

  Future<void> activate(String themeId) async {
    _rewards = await _service.setActiveTheme(_rewards, themeId);
    notifyListeners();
  }

  void dismissToast() {
    _toastTimer?.cancel();
    _toast = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _toastTimer?.cancel();
    super.dispose();
  }
}

class RewardsScope extends InheritedNotifier<RewardsProvider> {
  const RewardsScope({
    super.key,
    required RewardsProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static RewardsProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RewardsScope>();
    if (scope == null || scope.notifier == null) {
      throw FlutterError('RewardsScope is not available in this context.');
    }
    return scope.notifier!;
  }
}
