import 'package:flutter/material.dart';
import '../data/streak_repository.dart';

class StreakController extends ChangeNotifier {
  final StreakRepository _repository;

  StreakController({required StreakRepository repository})
      : _repository = repository {
    loadData();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreakData? _streakData;
  StreakData? get streakData => _streakData;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _streakData = await _repository.fetchStreakData();
    _isLoading = false;
    notifyListeners();
  }

}