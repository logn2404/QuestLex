import 'package:flutter/foundation.dart';

/// Cấu hình các cơ chế kích hoạt chụp màn hình.
class CaptureConfig {
  bool enableTimer;
  int timerIntervalMs;

  bool enableClick;
  int clickThreshold;

  bool enableScroll;
  double scrollThreshold;

  CaptureConfig({
    this.enableTimer = true,
    this.timerIntervalMs = 3000,
    this.enableClick = true,
    this.clickThreshold = 1,
    this.enableScroll = true,
    this.scrollThreshold = 300.0,
  });
}

/// Controller riêng quản lý cấu hình trigger, tách khỏi HomeController.
class TriggerConfigController extends ChangeNotifier {
  final CaptureConfig config = CaptureConfig();

  void updateConfig({
    bool? enableTimer,
    int? timerIntervalMs,
    bool? enableClick,
    int? clickThreshold,
    bool? enableScroll,
    double? scrollThreshold,
  }) {
    if (enableTimer != null) config.enableTimer = enableTimer;
    if (timerIntervalMs != null) config.timerIntervalMs = timerIntervalMs.clamp(100, 86400000);
    if (enableClick != null) config.enableClick = enableClick;
    if (clickThreshold != null) config.clickThreshold = clickThreshold.clamp(1, 1000000);
    if (enableScroll != null) config.enableScroll = enableScroll;
    if (scrollThreshold != null) config.scrollThreshold = scrollThreshold.clamp(1, 1000000).toDouble();

    notifyListeners();
  }
}
