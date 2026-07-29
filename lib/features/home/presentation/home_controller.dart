import 'dart:async';
import 'dart:ffi';
import 'dart:io';
//import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';

import '../../../services/game_timer_service.dart';
import '../../../services/screen_capture_service.dart';
import '../domain/models/dashboard_stats.dart';
import '../domain/repositories/dashboard_repository.dart';
import 'trigger_config_controller.dart';

// --- NATIVE HOOK GLOBAL VARIABLES ---
int _hMouseHook = 0;
HomeController? _activeControllerInstance;

// Biến lưu mốc thời gian click cuối cùng để chống Spam (Cooldown 500ms an toàn)
DateTime? _lastClickTime;
const Duration _clickCooldown = Duration(milliseconds: 500);

/// Low-Level Mouse Hook Callback từ Windows (C++ Native Level)
/// 🛡️ Đã bọc Future.microtask để trả về kết quả cho Windows lập tức, tránh nghẽn thread gây crash
int _mouseProc(int nCode, int wParam, int lParam) {
  try {
    if (nCode >= 0 && _activeControllerInstance != null) {
      if (_activeControllerInstance!.isScanningActive) {
        
        // 1. WM_LBUTTONDOWN (0x0201) - Click chuột trái
        if (wParam == WM_LBUTTONDOWN) {
          final now = DateTime.now();
          if (_lastClickTime == null || now.difference(_lastClickTime!) >= _clickCooldown) {
            _lastClickTime = now;

            // ⚡ Đẩy xử lý sang Dart Event Loop, giải phóng Windows Thread ngay!
            Future.microtask(() {
              _activeControllerInstance?.onGlobalMouseClick();
            });
          }
        } 
        // 2. WM_MOUSEWHEEL (0x020A) - Lăn chuột (Scroll Y-axis)
        else if (wParam == WM_MOUSEWHEEL) {
          final mouseStruct = Pointer<MSLLHOOKSTRUCT>.fromAddress(lParam).ref;
          int mouseData = mouseStruct.mouseData;
          int wheelDelta = (mouseData >> 16) & 0xFFFF;
          if (wheelDelta >= 0x8000) {
            wheelDelta -= 0x10000; // Xử lý số âm khi cuộn xuống
          }
          final delta = wheelDelta.toDouble();

          // ⚡ Đẩy xử lý sang Dart Event Loop
          Future.microtask(() {
            _activeControllerInstance?.onGlobalMouseScroll(delta);
          });
        }
      }
    }
  } catch (e) {
    debugPrint('⚠️ [MouseProc Safe Catch]: $e');
  }

  // Luôn trả về CallNextHookEx nhanh nhất có thể cho Windows
  return CallNextHookEx(_hMouseHook, nCode, wParam, lParam);
}

class HomeController extends ChangeNotifier {
  final DashboardRepository _repository;
  final GameTimerService _timerService;
  final ScreenCaptureService _captureService = ScreenCaptureService();
  final TriggerConfigController triggerConfigController;

  // Cấu hình linh hoạt cho 3 Triggers
  CaptureConfig get config => triggerConfigController.config;

  // Trạng thái Dashboard UI
  DashboardStats? _stats;
  bool _isLoading = false;
  bool _isScanningActive = false;

  // Bộ đếm trạng thái chụp
  Timer? _autoTimer;
  int _currentClickCount = 0;
  double _accumulatedScrollDelta = 0.0;
  bool _isCapturingNow = false;

  HomeController({
    required this._repository,
    required GameTimerService timerService,
    TriggerConfigController? triggerConfigController,
  })  : _timerService = timerService,
        triggerConfigController = triggerConfigController ?? TriggerConfigController() {
    this.triggerConfigController.addListener(_handleTriggerConfigChanged);
    loadStats();
  }

  // --- GETTERS CHO HOME_PAGE UI ---
  bool get isScanningActive => _isScanningActive;
  String get formattedTime => _timerService.formattedTime;
  bool get isExceeding3Hours => _timerService.isExceeding3Hours;
  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;

  // --- TẢI DỮ LIỆU THỐNG KÊ ---
  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();

    _stats = await _repository.getDashboardStats();

    _isLoading = false;
    notifyListeners();
  }

  // --- CẬP NHẬT CẤU HÌNH TRIGGER TỪ UI SETTINGS ---
  void updateConfig({
    bool? enableTimer,
    int? timerIntervalMs,
    bool? enableClick,
    int? clickThreshold,
    bool? enableScroll,
    double? scrollThreshold,
  }) {
    triggerConfigController.updateConfig(
      enableTimer: enableTimer,
      timerIntervalMs: timerIntervalMs,
      enableClick: enableClick,
      clickThreshold: clickThreshold,
      enableScroll: enableScroll,
      scrollThreshold: scrollThreshold,
    );

    // Reset lại chu kỳ đếm nếu tính năng quét đang bật
    if (_isScanningActive) {
      _resetAllCycles();
    }
    notifyListeners();
  }

  void _handleTriggerConfigChanged() {
    if (_isScanningActive) {
      _resetAllCycles();
    }
    notifyListeners();
  }

  // --- 1. KHỞI CHẠY / DỪNG QUÉT ---
  void toggleScanning(bool active) {
    _isScanningActive = active;
    if (active) {
      _timerService.start();
      _startTriggers();
    } else {
      _timerService.stop();
      _stopTriggers();
    }
    notifyListeners();
  }

  void _startTriggers() {
    _resetAllCycles();
    _initGlobalMouseHooks();
  }

  void _stopTriggers() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _removeGlobalMouseHooks();
  }

  // --- 2. ĐĂNG KÝ MOUSE HOOK (WINDOWS NATIVE) ---
  void _initGlobalMouseHooks() {
    if (!Platform.isWindows) return;

    try {
      _activeControllerInstance = this;
      if (_hMouseHook == 0) {
        final mouseProcPointer = Pointer.fromFunction<HOOKPROC>(_mouseProc, 0);
        _hMouseHook = SetWindowsHookEx(
          WH_MOUSE_LL,
          mouseProcPointer,
          GetModuleHandle(nullptr),
          0,
        );
      }
      debugPrint('🖱️ [Native Win32 Hook]: Đã kích hoạt Hook chuột thành công.');
    } catch (e) {
      debugPrint('❌ [Mouse Hook Error]: $e');
    }
  }

  void _removeGlobalMouseHooks() {
    if (!Platform.isWindows) return;
    try {
      if (_hMouseHook != 0) {
        UnhookWindowsHookEx(_hMouseHook);
        _hMouseHook = 0;
      }
      _activeControllerInstance = null;
      debugPrint('🛑 [Native Win32 Hook]: Đã gỡ bỏ Hook chuột.');
    } catch (e) {
      debugPrint('❌ [Mouse Hook Stop Error]: $e');
    }
  }

  // --- 3. CALLBACK HANDLERS SỰ KIỆN CHUỘT ---
  void onGlobalMouseClick() {
    if (!config.enableClick || !_isScanningActive || _isCapturingNow) return;

    _currentClickCount++;
    debugPrint('🖱️ Global Click: $_currentClickCount/${config.clickThreshold}');

    if (_currentClickCount >= config.clickThreshold) {
      _triggerCapture('Mouse Click ($_currentClickCount lần)');
    }
  }

  void onGlobalMouseScroll(double deltaY) {
    if (!config.enableScroll || !_isScanningActive || _isCapturingNow) return;

    _accumulatedScrollDelta += deltaY.abs();
    debugPrint('📜 Scroll Y Delta: ${_accumulatedScrollDelta.toStringAsFixed(0)}/${config.scrollThreshold}');

    if (_accumulatedScrollDelta >= config.scrollThreshold) {
      _triggerCapture('Mouse Scroll (${_accumulatedScrollDelta.toStringAsFixed(0)} px)');
    }
  }

  // --- 4. CORE TRIGGER CAPTURE & RESET ---
  Future<void> _triggerCapture(String triggerSource) async {
    if (!_isScanningActive || _isCapturingNow) return;

    _isCapturingNow = true;
    debugPrint('🚀 [TRIGGER] Kích hoạt chụp từ: $triggerSource');

    try {
      String? path = await _captureService.captureEntireScreen();
      if (path != null) {
        debugPrint('📸 [Chụp thành công]: $path');
        // TODO: Sẽ gửi 'path' này cho Model ONNX nhận diện chữ ở bước tiếp theo
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Lỗi chụp]: $e\n$stackTrace');
    } finally {
      _isCapturingNow = false;
      _resetAllCycles(); // 🔄 Reset chu kỳ chụp ngay sau khi chụp xong
    }
  }

  /// Reset lại toàn bộ Timer, bộ đếm Click và Scroll
  void _resetAllCycles() {
    _autoTimer?.cancel();
    if (config.enableTimer && _isScanningActive) {
      _autoTimer = Timer(Duration(milliseconds: config.timerIntervalMs), () {
        _triggerCapture('Timer (${config.timerIntervalMs}ms)');
      });
    }

    _currentClickCount = 0;
    _accumulatedScrollDelta = 0.0;
  }

  @override
  void dispose() {
    triggerConfigController.removeListener(_handleTriggerConfigChanged);
    _stopTriggers();
    triggerConfigController.dispose();
    _timerService.dispose();
    super.dispose();
  }
}