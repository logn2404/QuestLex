import 'dart:async';
import 'package:flutter/material.dart';

class GameTimerService {
  int limitInSeconds = 10800; // 3 hours in seconds
  Timer? _timer;
  int _secondsScanned = 0;
  final VoidCallback onTick;

  GameTimerService({required this.onTick});

  int get secondsScanned => _secondsScanned;

  void start() {
    _timer?.cancel();
    _secondsScanned = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsScanned++;
      onTick();
    });
  }

  void stop() {
    _timer?.cancel();
  }

  void dispose() {
    stop();
  }

  // Kiểm tra xem thời gian đã vượt quá 3 tiếng (10800 giây) chưa
  bool get isExceeding3Hours => _secondsScanned >= limitInSeconds;

  String get formattedTime {
    int hours = _secondsScanned ~/ 3600;
    int minutes = (_secondsScanned % 3600) ~/ 60;
    int seconds = _secondsScanned % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}