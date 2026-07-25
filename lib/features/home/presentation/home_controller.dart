import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../../services/game_timer_service.dart';
import '../../../services/screen_capture_service.dart';
import '../domain/models/dashboard_stats.dart';
import '../domain/repositories/dashboard_repository.dart';

class HomeController extends ChangeNotifier {
  final DashboardRepository _repository;
  final GameTimerService _timerService;
  final ScreenCaptureService _captureService = ScreenCaptureService();

  bool _isScanningActive = false;
  DashboardStats? _stats;
  bool _isLoading = false;

  Timer? _captureTimer;
  bool _isCapturingNow = false; // 👈 THÊM DÒNG NÀY ĐỂ HẾT LỖI UNDEFINED

  HomeController({
    required DashboardRepository repository,
    required GameTimerService timerService,
  })  : _repository = repository,
        _timerService = timerService {
    loadStats();
  }
  
  // ... các đoạn code bên dưới giữ nguyên

  bool get isScanningActive => _isScanningActive;
  String get formattedTime => _timerService.formattedTime;
  bool get isExceeding3Hours => _timerService.isExceeding3Hours;
  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();

    _stats = await _repository.getDashboardStats();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleScanning(bool value, BuildContext context) async {
    if (value) {
      bool hasPermission = await _captureService.checkPermission();
      if (!hasPermission && Platform.isMacOS) {
        return;
      }

      _isScanningActive = true;
      _timerService.start();
      
      // 🚀 BẬT CHỤP ĐỊNH KỲ: Cứ 3 giây chụp 1 lần để AI xử lý
      _startAutoCapture();
      
      notifyListeners();
    } else {
      _isScanningActive = false;
      _timerService.stop();
      
      // 🛑 TẮT CHỤP ĐỊNH KỲ
      _stopAutoCapture();
      
      notifyListeners();
    }
  }

  /// Hàm khởi chạy vòng lặp chụp màn hình
  /// Khởi chạy vòng lặp chụp định kỳ (Có độ trễ 3s cho tấm đầu tiên)
  void _startAutoCapture() {
    _stopAutoCapture(); // Reset timer cũ nếu có

    // ⏳ Đợi 3 giây để người dùng kịp Alt+Tab sang Game/Ứng dụng, sau đó bắt đầu vòng lặp
    _captureTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isScanningActive) {
        await _performCapture();
      }
    });
  }

  /// Hàm thực hiện 1 lượt chụp an toàn (tránh bị nghẽn/đè lặp)
  Future<void> _performCapture() async {
    if (_isCapturingNow) return; // Nếu lượt chụp trước chưa xong thì bỏ qua
    _isCapturingNow = true;

    try {
      String? path = await _captureService.captureEntireScreen();
      if (path != null) {
        debugPrint('📸 [Auto-Capture] Đã chụp thành công: $path');
      }
    } catch (e) {
      debugPrint('❌ [Auto-Capture Error]: $e');
    } finally {
      _isCapturingNow = false;
    }
  }

  /// Hàm dừng chụp
  void _stopAutoCapture() {
    _captureTimer?.cancel();
    _captureTimer = null;
  }

  @override
  void dispose() {
    _stopAutoCapture();
    _timerService.dispose();
    super.dispose();
  }
}