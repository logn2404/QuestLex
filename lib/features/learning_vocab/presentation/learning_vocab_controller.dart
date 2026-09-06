import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/models/daily_cefr_count.dart';
import '../domain/models/learning_vocab_item.dart';
import '../domain/repositories/learning_vocab_repository.dart';
import '../domain/utils/trend_analyzer.dart';

class LearningVocabController extends ChangeNotifier {
  final LearningVocabRepository _repository;

  List<LearningVocabItem> _allVocab = [];
  List<LearningVocabItem> _analyticsVocab = [];
  List<LearningVocabItem> _filteredVocab = [];

  final Set<String> _selectedItemIds = {};
  bool _isSelectionMode = false;
  double _leftPanelWidth = 320.0;
  String _searchQuery = '';
  bool _isLoading = false;

  Timer? _debounceTimer;
  Timer? _autoRefreshTimer;
  bool _isDisposed = false;

  List<LearningVocabItem> get vocabList => _filteredVocab;
  Set<String> get selectedItemIds => _selectedItemIds;
  bool get isSelectionMode => _isSelectionMode;
  double get leftPanelWidth => _leftPanelWidth;
  bool get isLoading => _isLoading;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  // 🎯 Thống kê Analytics tính toán qua TrendAnalyzer
    List<DailyCEFRCount> get dailyStats =>
      TrendAnalyzer.analyzeDailyStats(_analyticsVocab);
    List<DailyCEFRCount> get monthlyStats =>
      TrendAnalyzer.analyzeMonthlyStats(_analyticsVocab);

  LearningVocabController({required this._repository}) {
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadData(isSilent: true);
    });
  }

  Future<void> loadData({bool isSilent = false}) async {
    if (_isDisposed) return;

    if (!isSilent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _repository.getLearningVocab(),
        _repository.getMasteredVocabForAnalytics(),
      ]);
      if (_isDisposed) return;
      final learningData = results[0];
      final masteredData = results[1];
      _allVocab = learningData;
      _analyticsVocab = _mergeAnalyticsData(learningData, masteredData);
      _applyFilter();
    } catch (e) {
      if (_isDisposed) return;
      if (!isSilent) _isLoading = false;
      if (!_isDisposed) notifyListeners();
      if (!isSilent) rethrow; // Ném lỗi cho UI bắt và hiển thị AlertDialog
    }

    if (!isSilent) _isLoading = false;
    if (!_isDisposed) notifyListeners();
  }

  void updateLeftPanelWidth(double delta) {
    _leftPanelWidth = (_leftPanelWidth + delta).clamp(280.0, 480.0);
    notifyListeners();
  }

  /// 🎯 1. BẬT / TẮT CHẾ ĐỘ CHỌN TỪ TỪ NÚT BẤM (TOGGLE SELECTION MODE)
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedItemIds.clear();
    }
    notifyListeners();
  }

  /// 🎯 2. CHỌN / BỎ CHỌN MỘT TỪ VỰNG CỤ THỂ
  void toggleSelectItem(String id) {
    if (_selectedItemIds.contains(id)) {
      _selectedItemIds.remove(id);
      // Auto reset mode về false khi bỏ chọn hết
      if (_selectedItemIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedItemIds.add(id);
      // Auto bật chế độ chọn khi bấm chọn từ đầu tiên
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  /// 🎯 3. XÓA SẠCH TẤT CẢ LỰA CHỌN
  void clearAllSelection() {
    _selectedItemIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  void search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _applyFilter();
      notifyListeners();
    });
  }

  void _applyFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredVocab = List.from(_allVocab);
    } else {
      _filteredVocab = _allVocab.where((item) {
        final q = _searchQuery.toLowerCase();
        return item.word.toLowerCase().contains(q) ||
            item.meaning.toLowerCase().contains(q);
      }).toList();
    }
  }

  List<LearningVocabItem> _mergeAnalyticsData(
    List<LearningVocabItem> learningData,
    List<LearningVocabItem> masteredData,
  ) {
    final merged = <String, LearningVocabItem>{};
    for (final item in [...learningData, ...masteredData]) {
      merged[item.id] = item;
    }
    return merged.values.toList();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}