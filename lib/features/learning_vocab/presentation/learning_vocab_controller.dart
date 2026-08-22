import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/models/daily_cefr_count.dart';
import '../domain/models/learning_vocab_item.dart';
import '../domain/repositories/learning_vocab_repository.dart';
import '../domain/utils/trend_analyzer.dart';

class LearningVocabController extends ChangeNotifier {
  final LearningVocabRepository _repository;

  List<LearningVocabItem> _allVocab = [];
  List<LearningVocabItem> _filteredVocab = [];

  final Set<String> _selectedItemIds = {};
  bool _isSelectionMode = false;
  double _leftPanelWidth = 320.0;
  String _searchQuery = '';
  bool _isLoading = false;

  Timer? _debounceTimer;

  List<LearningVocabItem> get vocabList => _filteredVocab;
  Set<String> get selectedItemIds => _selectedItemIds;
  bool get isSelectionMode => _isSelectionMode;
  double get leftPanelWidth => _leftPanelWidth;
  bool get isLoading => _isLoading;

  // 🎯 Thống kê Analytics tính toán qua TrendAnalyzer
  List<DailyCEFRCount> get dailyStats => TrendAnalyzer.analyzeDailyStats(_allVocab);
  List<DailyCEFRCount> get monthlyStats => TrendAnalyzer.analyzeMonthlyStats(_allVocab);

  LearningVocabController({required this._repository});

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _repository.getLearningVocab();
      _allVocab = data;
      _applyFilter();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow; // Ném lỗi cho UI bắt và hiển thị AlertDialog
    }

    _isLoading = false;
    notifyListeners();
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}