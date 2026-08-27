import 'package:flutter/material.dart';
import '../data/fake_streak_repository.dart';

enum StreakViewMode { growthChart, topVocabTable, activityHeatmap }

class StreakController extends ChangeNotifier {
  final FakeStreakRepository _repository;

  StreakController({required this._repository}) {
    loadData();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreakData? _streakData;
  StreakData? get streakData => _streakData;

  StreakViewMode _currentMode = StreakViewMode.growthChart;
  StreakViewMode get currentMode => _currentMode;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _streakData = await _repository.fetchStreakData();
    _isLoading = false;
    notifyListeners();
  }

  void setViewMode(StreakViewMode mode) {
    _currentMode = mode;
    notifyListeners();
  }
}