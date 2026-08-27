import 'dart:async';
import 'package:flutter/foundation.dart';
import '../presentation/trigger_config_controller.dart';

class CaptureTriggerManager {
  final TriggerConfigController triggerConfigController;
  final Future<void> Function(String source) onTriggerCapture;

  Timer? _autoTimer;
  int _currentClickCount = 0;
  double _accumulatedScrollDelta = 0.0;
  bool _isScanningActive = false;

  CaptureTriggerManager({
    required this.triggerConfigController,
    required this.onTriggerCapture,
  });

  CaptureConfig get config => triggerConfigController.config;

  // Xử lý Click chuột
  void handleMouseClick() {
    if (!config.enableClick) return;

    _currentClickCount++;
    debugPrint('🖱️ Global Click: $_currentClickCount/${config.clickThreshold}');

    if (_currentClickCount >= config.clickThreshold) {
      final clickCount = _currentClickCount;
      _fireCapture('Mouse Click ($clickCount lần)');
    }
  }

  // Xử lý Cuộn chuột
  void handleMouseScroll(double deltaY) {
    if (!config.enableScroll) return;

    _accumulatedScrollDelta += deltaY.abs();
    debugPrint('📜 Scroll Y Delta: ${_accumulatedScrollDelta.toStringAsFixed(0)}/${config.scrollThreshold}');

    if (_accumulatedScrollDelta >= config.scrollThreshold) {
      final scrollDelta = _accumulatedScrollDelta;
      _fireCapture('Mouse Scroll (${scrollDelta.toStringAsFixed(0)} px)');
    }
  }

  // 🛡️ RESET CHU KỲ (Hủy Timer cũ để không dồn hàng)
  void resetCycles(bool isScanningActive) {
    _isScanningActive = isScanningActive;
    _autoTimer?.cancel();
    _autoTimer = null;

    _currentClickCount = 0;
    _accumulatedScrollDelta = 0.0;

    if (config.enableTimer && isScanningActive) {
      _autoTimer = Timer(Duration(milliseconds: config.timerIntervalMs), () {
        _fireCapture('Timer (${config.timerIntervalMs}ms)');
      });
    }
  }

  void _fireCapture(String source) {
    resetCycles(_isScanningActive);
    onTriggerCapture(source);
  }

  // Dừng hẳn Trigger
  void stop() {
    _isScanningActive = false;
    _autoTimer?.cancel();
    _autoTimer = null;
    _currentClickCount = 0;
    _accumulatedScrollDelta = 0.0;
  }
}