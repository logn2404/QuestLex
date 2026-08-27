import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/ai_service.dart';
import '../../../services/game_timer_service.dart';
import '../../../services/screen_capture_service.dart';
import '../domain/models/dashboard_stats.dart';
import '../domain/repositories/dashboard_repository.dart';
import '../services/capture_trigger_manager.dart';
import '../services/win32_mouse_hook_service.dart';
import 'trigger_config_controller.dart';

class HomeController extends ChangeNotifier {
  final DashboardRepository _repository;
  final GameTimerService _timerService;
  final ScreenCaptureService _captureService = ScreenCaptureService();
  final TriggerConfigController triggerConfigController;

  final Win32MouseHookService _hookService = Win32MouseHookService();
  late final CaptureTriggerManager _triggerManager;

  final String baseUrl;

  // Trạng thái Dashboard UI
  DashboardStats? _stats;
  bool _isLoading = false;
  bool _isScanningActive = false;
  bool _isCapturingNow = false;
  bool _isDisposed = false;
  int _scanOperation = 0;

  HomeController({
    required this._repository,
    required this._timerService,
    TriggerConfigController? triggerConfigController,
    this.baseUrl = 'http://127.0.0.1:8000',
  })  : triggerConfigController =
            triggerConfigController ?? TriggerConfigController() {
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

  String get goldenHourCountdown {
    final now = DateTime.now();

    final slot1Start = DateTime(now.year, now.month, now.day, 7);
    final slot1End = DateTime(now.year, now.month, now.day, 10);
    final slot2Start = DateTime(now.year, now.month, now.day, 20);
    final slot2End = DateTime(now.year, now.month, now.day, 22, 30);

    if (!now.isBefore(slot1Start) && now.isBefore(slot1End)) {
      return '🔥 Đang Giờ Vàng! Còn ${_formatDuration(slot1End.difference(now))} (x1.5 EXP)';
    }

    if (!now.isBefore(slot2Start) && now.isBefore(slot2End)) {
      return '🔥 Đang Giờ Vàng! Còn ${_formatDuration(slot2End.difference(now))} (x1.5 EXP)';
    }

    if (now.isBefore(slot1Start)) {
      return '⏳ Giờ vàng sau ${_formatDuration(slot1Start.difference(now))} (x1.5 EXP)';
    }

    if (now.isBefore(slot2Start)) {
      return '⏳ Giờ vàng sau ${_formatDuration(slot2Start.difference(now))} (x1.5 EXP)';
    }

    final tomorrowSlot1 = slot1Start.add(const Duration(days: 1));
    return '⏳ Giờ vàng sau ${_formatDuration(tomorrowSlot1.difference(now))} (x1.5 EXP)';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  // --- TẢI DỮ LIỆU THỐNG KÊ THỰC TẾ TỪ BACKEND FASTAPI ---
  static int calculateMonthlyDiffForItems(
    dynamic items, {
    required String? Function(Map<String, dynamic>) dateExtractor,
  }) {
    if (items is! List || items.isEmpty) {
      return 0;
    }

    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month);
    final previousMonthStart = DateTime(now.year, now.month - 1);

    int currentMonthCount = 0;
    int previousMonthCount = 0;

    for (final item in items) {
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);
      final rawDate = dateExtractor(map);
      if (rawDate == null || rawDate.trim().isEmpty) continue;

      DateTime? parsedDate;
      try {
        final normalized = rawDate.contains(' ') ? rawDate.replaceFirst(' ', 'T') : rawDate;
        parsedDate = DateTime.parse(normalized);
      } catch (_) {
        continue;
      }

      final monthStart = DateTime(parsedDate.year, parsedDate.month);
      if (monthStart == currentMonthStart) {
        currentMonthCount++;
      } else if (monthStart == previousMonthStart) {
        previousMonthCount++;
      }
    }

    return currentMonthCount - previousMonthCount;
  }

  Future<void> loadStats() async {
    _isLoading = true;
    Future.microtask(notifyListeners);

    if (_stats == null) {
      try {
        _stats = await _repository.getDashboardStats();
        if (!_isDisposed) {
          _isLoading = false;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ [Load Local Stats Error]: $e');
      }
    }

    try {
      int inventoryCount = 0;
      int learningCount = 0;
      int inventoryMonthlyDiff = 0;
      int learningMonthlyDiff = 0;
      int pendingStudyCount = 0;

      // 1. Lấy tổng số từ Kho từ vựng (Mastery = 100%)
        final invRes = await http
          .get(Uri.parse('$baseUrl/api/inventory?user_id=user_dev_01'))
          .timeout(const Duration(seconds: 5));
      if (invRes.statusCode == 200) {
        final data = jsonDecode(invRes.body);
        final List words = data['words'] ?? [];
        inventoryCount = ((data['total'] ?? words.length) as num).toInt();
        inventoryMonthlyDiff = calculateMonthlyDiffForItems(
          words,
          dateExtractor: (item) => item['masteredAt'] ?? item['createdAt'] ?? item['created_at'],
        );
      }

      // 2. Lấy tổng số từ Từ vựng đang học (Mastery < 100%)
        final learnRes = await http
          .get(Uri.parse('$baseUrl/api/learning?user_id=user_dev_01'))
          .timeout(const Duration(seconds: 5));
      if (learnRes.statusCode == 200) {
        final data = jsonDecode(learnRes.body);
        final List words = data['words'] ?? [];
        learningCount = ((data['total'] ?? words.length) as num).toInt();
        learningMonthlyDiff = calculateMonthlyDiffForItems(
          words,
          dateExtractor: (item) => item['createdAt'] ?? item['created_at'] ?? item['masteredAt'],
        );
      }

      // 3. Lấy chính xác số từ chờ học giống hệt StudyHeaderBanner / Flashcards API
      final flashcardRes = await http
          .get(
            Uri.parse('$baseUrl/api/flashcards?user_id=user_dev_01&limit=30&mode=study'),
          )
          .timeout(const Duration(seconds: 5));
      if (flashcardRes.statusCode == 200) {
        final data = jsonDecode(flashcardRes.body);
        final List words = data['words'] ?? [];
        pendingStudyCount = words.length;
      }

      _stats = DashboardStats(
        totalInventoryVocab: inventoryCount,
        inventoryMonthlyDiff: inventoryMonthlyDiff,
        totalLearningVocab: learningCount,
        learningMonthlyDiff: learningMonthlyDiff,
        pendingVocab: pendingStudyCount,
        streakDays: 1,
      );
    } catch (e) {
      debugPrint('❌ [Load Stats Error]: $e');
    } finally {
      _isLoading = false;
      Future.microtask(notifyListeners);
    }
  }

  // --- KHỞI CHẠY / DỪNG QUÉT ---
  Future<void> toggleScanning(bool active) async {
    final operation = ++_scanOperation;
    if (active) {
      await _captureService.clearAllCaptures();
      if (operation != _scanOperation || _isDisposed) return;
    }

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

  // --- CORE CAPTURE & AI PROCESSING ---
  Future<void> _triggerCapture(String triggerSource) async {
    if (_isDisposed || !_isScanningActive || _isCapturingNow) return;

    _isCapturingNow = true;
    _hookService.isBusy = true;

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
        
        debugPrint('🧠 [AI Scan]: Đang kích hoạt Python AI Backend quét thư mục images/...');
        unawaited(_processCaptureInBackground(_durationMsFromTrigger(triggerSource)));
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Lỗi chụp / Xử lý AI]: $e\n$stackTrace');
    } finally {
      _isCapturingNow = false;
      _hookService.isBusy = false;
      if (!_isDisposed) {
        _triggerManager.resetCycles(_isScanningActive);
      }
    }
  }

  int? _durationMsFromTrigger(String triggerSource) {
    final match = RegExp(r'^Timer \((\d+)ms\)$').firstMatch(triggerSource);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  Future<void> _processCaptureInBackground(int? durationMs) async {
    try {
      final scanResult = await AIService.triggerScanFolder(durationMs: durationMs);

      if (scanResult != null && scanResult['success'] == true) {
        final int totalFound = scanResult['total_vocab_found'] ?? 0;
        debugPrint('✅ [AI Scan Thành công]: Đã trích xuất & lưu $totalFound từ vựng mới vào DB.');

        if (!_isDisposed) {
          await loadStats();
        }
      } else {
        debugPrint('⚠️ [AI Scan]: Không phát hiện từ vựng mới hoặc chưa bật Backend Python.');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Lỗi xử lý AI nền]: $e\n$stackTrace');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scanOperation++;
    _isScanningActive = false;
    _hookService.isActive = false;
    triggerConfigController.removeListener(_handleTriggerConfigChanged);
    _triggerManager.stop();
    _hookService.stop();
    triggerConfigController.dispose();
    _timerService.dispose();
    super.dispose();
  }
}