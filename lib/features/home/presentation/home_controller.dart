import 'package:flutter/foundation.dart';

import '../../../services/game_timer_service.dart';
import '../data/repositories/fake_dashboard_repository.dart';
import '../domain/models/dashboard_stats.dart';
import '../domain/repositories/dashboard_repository.dart';

class HomeController extends ChangeNotifier {
  HomeController({DashboardRepository? repository, GameTimerService? timerService})
      : _repository = repository ?? FakeDashboardRepository() {
    _timerService = timerService ??
        GameTimerService(
          onTick: () {
            if (!_isDisposed) {
              notifyListeners();
            }
          },
        );
    _stats = _repository.getDashboardStats();
  }

  final DashboardRepository _repository;
  late final GameTimerService _timerService;

  bool _isScanningActive = false;
  DashboardStats _stats = const DashboardStats(
    totalVocab: 0,
    addedVocab: 0,
    learningVocab: 0,
    masterChange: 0,
    pendingVocab: 0,
    streakDays: 0,
  );
  bool _isDisposed = false;

  bool get isScanningActive => _isScanningActive;
  DashboardStats get stats => _stats;
  String get formattedTime => _timerService.formattedTime;
  bool get isExceeding3Hours => _timerService.isExceeding3Hours;

  Future<void> toggleScan(bool value, {Future<bool> Function()? confirmScan}) async {
    if (value) {
      final confirmed = confirmScan == null ? true : await confirmScan();
      if (confirmed) {
        _isScanningActive = true;
        _timerService.start();
      } else {
        _isScanningActive = false;
      }
    } else {
      _isScanningActive = false;
      _timerService.stop();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timerService.dispose();
    _isDisposed = true;
    super.dispose();
  }
}
