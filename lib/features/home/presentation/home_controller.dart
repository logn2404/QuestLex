import 'dart:io';
import 'package:flutter/material.dart';

import '../../../services/game_timer_service.dart';
import '../../../services/screen_capture_service.dart';
import '../domain/models/dashboard_stats.dart';
import '../domain/repositories/dashboard_repository.dart';
import '../services/capture_trigger_manager.dart';
import '../services/win32_mouse_hook_service.dart';
import 'trigger_config_controller.dart';

const int MaxCaptureFiles = 10; // Giới hạn số tấm ảnh lưu trữ trong bộ nhớ đệm

class HomeController extends ChangeNotifier {
  final DashboardRepository _repository;
  final GameTimerService _timerService;
  final ScreenCaptureService _captureService = ScreenCaptureService();
  final TriggerConfigController triggerConfigController;

  final Win32MouseHookService _hookService = Win32MouseHookService();
  late final CaptureTriggerManager _triggerManager;

  // Trạng thái Dashboard UI
  DashboardStats? _stats;
  bool _isLoading = false;
  bool _isScanningActive = false;
  bool _isCapturingNow = false;
  bool _isDisposed = false;

  HomeController({
    required DashboardRepository repository,
    required GameTimerService timerService,
    TriggerConfigController? triggerConfigController,
  })  : _repository = repository,
        _timerService = timerService,
        triggerConfigController = triggerConfigController ?? TriggerConfigController() {
    
    // Khởi tạo Trigger Manager
    _triggerManager = CaptureTriggerManager(
      triggerConfigController: this.triggerConfigController,
      onTriggerCapture: _triggerCapture,
    );

    // Bind event từ Win32 Hook sang Trigger Manager
    _hookService.onClick = _triggerManager.handleMouseClick;
    _hookService.onScroll = _triggerManager.handleMouseScroll;

    this.triggerConfigController.addListener(_handleTriggerConfigChanged);
    loadStats();
  }

  // --- GETTERS CHO HOME_PAGE UI ---
  bool get isScanningActive => _isScanningActive;
  String get formattedTime => _timerService.formattedTime;
  bool get isExceeding3Hours => _timerService.isExceeding3Hours;
  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  // --- TẢI DỮ LIỆU THỐNG KÊ ---
  Future<void> loadStats() async {
    _isLoading = true;
    Future.microtask(notifyListeners);

    try {
      _stats = await _repository.getDashboardStats();
    } catch (e) {
      debugPrint('❌ [Load Stats Error]: $e');
      _stats = null;
    } finally {
      _isLoading = false;
      Future.microtask(notifyListeners);
    }
  }

  // --- KHỞI CHẠY / DỪNG QUÉT ---
  void toggleScanning(bool active) {
    _isScanningActive = active;
    _hookService.isActive = active;

    if (active) {
      _timerService.start();
      _triggerManager.resetCycles(true);
      _hookService.start();
    } else {
      _timerService.stop();
      _triggerManager.stop();
      _hookService.stop();
    }
    notifyListeners();
  }

  // --- CẬP NHẬT CẤU HÌNH TRIGGER ---
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

    if (_isScanningActive) {
      _triggerManager.resetCycles(true);
    }
    notifyListeners();
  }

  void _handleTriggerConfigChanged() {
    if (_isScanningActive) {
      _triggerManager.resetCycles(true);
    }
    notifyListeners();
  }

  // --- HÀM GIỚI HẠN DỌN DẸP CACHE (TỐI ĐA 10 TẤM) ---
  Future<void> _cleanOldCaptures(String latestFilePath, {int maxFiles = 10}) async {
    try {
      final file = File(latestFilePath);
      final directory = file.parent;

      if (!await directory.exists()) return;

      // Lấy toàn bộ file .png trong thư mục capture
      List<FileSystemEntity> files = directory
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.png'))
          .toList();

      // Nếu số file vượt quá giới hạn (10 tấm)
      if (files.length > maxFiles) {
        // Sắp xếp file theo thời gian chỉnh sửa (Cũ nhất lên đầu)
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

        int filesToDelete = files.length - maxFiles;

        for (int i = 0; i < filesToDelete; i++) {
          await files[i].delete();
          debugPrint('🗑️ [Cache Manager]: Đã xóa ảnh cũ vượt giới hạn: ${files[i].path}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Clean Captures Error]: $e');
    }
  }

  // --- CORE CAPTURE ---
  Future<void> _triggerCapture(String triggerSource) async {
    if (!_isScanningActive || _isCapturingNow) return;

    _isCapturingNow = true;
    _hookService.isBusy = true; // Bận chụp -> Tạm khóa nhận hook

    debugPrint('🚀 [TRIGGER] Kích hoạt chụp từ: $triggerSource');

    try {
      String? path = await _captureService
          .captureEntireScreen()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        debugPrint('⚠️ [Capture Timeout]: Quá 3 giây không nhận phản hồi.');
        return null;
      });

      if (path != null) {
        debugPrint('📸 [Chụp thành công]: $path');
        
        // 🛡️ DỌN DẸP BỘ NHỚ ĐỆM: Giữ tối đa 10 tấm ảnh mới nhất
        await _cleanOldCaptures(path, maxFiles: MaxCaptureFiles);

        // TODO: Gửi 'path' này cho Model AI ONNX xử lý
        // await _aiService.processImage(path);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Lỗi chụp]: $e\n$stackTrace');
    } finally {
      _isCapturingNow = false;
      _hookService.isBusy = false; // Mở lại hook
      _triggerManager.resetCycles(_isScanningActive); // Tạo Timer chu kỳ mới
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    triggerConfigController.removeListener(_handleTriggerConfigChanged);
    _triggerManager.stop();
    _hookService.stop();
    triggerConfigController.dispose();
    _timerService.dispose();
    super.dispose();
  }
}