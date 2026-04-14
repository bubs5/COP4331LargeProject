import 'package:flutter/material.dart';

import '../models/rewards.dart';
import 'rewardsService.dart';

final RewardsController rewardsController = RewardsController();

class RewardsController extends ChangeNotifier {
  final RewardsService _service = RewardsService();

  RewardsState _state = RewardsState.initial();
  bool _loading = true;
  String _toastMessage = '';

  RewardsState get state => _state;
  bool get loading => _loading;
  String get toastMessage => _toastMessage;

  RewardTheme get activeTheme => _service.getThemeById(_state.activeThemeId);
  List<RewardTheme> get themes => RewardsService.themes;
  Map<String, RewardEvent> get rewardEvents => RewardsService.rewardEvents;

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    try {
      _state = await _service.loadRewards();
    } catch (_) {
      _state = RewardsState.initial();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> unlockTheme(String themeId) async {
    _state = await _service.unlockTheme(_state, themeId);
    notifyListeners();
  }

  Future<void> activateTheme(String themeId) async {
    _state = await _service.activateTheme(_state, themeId);
    notifyListeners();
  }

  Future<void> award(
      RewardEventType type, {
        int multiplier = 1,
      }) async {
    final result = await _service.awardPoints(
      _state,
      type,
      multiplier: multiplier,
    );

    _state = result.state;
    _toastMessage =
    '${RewardsService.rewardEvents[type]?.icon ?? '⭐'} +${result.entry.points} ${result.entry.label}';
    notifyListeners();
  }

  void clearToast() {
    _toastMessage = '';
    notifyListeners();
  }
}