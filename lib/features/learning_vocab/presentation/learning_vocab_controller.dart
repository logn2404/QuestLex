import 'dart:async'; // Import dart:async để dùng Timer
import 'package:flutter/material.dart';
import '../domain/models/daily_cefr_count.dart';
import '../domain/models/learning_vocab_item.dart';
import '../domain/repositories/learning_vocab_repository.dart';

class LearningVocabController extends ChangeNotifier {
  final LearningVocabRepository _repository;

  List<LearningVocabItem> _allVocab = [];
  List<LearningVocabItem> _filteredVocab = [];
  List<DailyCEFRCount> _dailyStats = [];
  List<DailyCEFRCount> _monthlyStats = [];

  final Set<String> _selectedItemIds = {};
  bool _isSelectionMode = false;
  double _leftPanelWidth = 320.0;
  String _searchQuery = '';
  bool _isLoading = false;

  // Khai báo Timer cho Debounce
  Timer? _debounceTimer;

  List<LearningVocabItem> get vocabList => _filteredVocab;
  List<DailyCEFRCount> get dailyStats => _dailyStats;
  List<DailyCEFRCount> get monthlyStats => _monthlyStats;
  Set<String> get selectedItemIds => _selectedItemIds;
  bool get isSelectionMode => _isSelectionMode;
  double get leftPanelWidth => _leftPanelWidth;
  bool get isLoading => _isLoading;

  LearningVocabController({required this._repository}) {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _dailyStats = await _repository.getDailyStats();
    _monthlyStats = await _repository.getMonthlyStats();
    _allVocab = await _repository.getLearningVocab();

    _applyFilter();
    _isLoading = false;
    notifyListeners();
  }

  void updateLeftPanelWidth(double delta) {
    _leftPanelWidth = (_leftPanelWidth + delta).clamp(280.0, 480.0);
    notifyListeners();
  }

  /// Bật/Tắt chế độ chọn thủ công từ nút Bấm
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedItemIds.clear();
    }
    notifyListeners();
  }

  /// 🚀 CẬP NHẬT: Chọn/Bỏ chọn từ vựng với Auto-Reset & Auto-Enable UX
  void toggleSelectItem(String id) {
    if (_selectedItemIds.contains(id)) {
      _selectedItemIds.remove(id);

      // 🎯 Auto reset chế độ chọn về ban đầu khi deselect từ cuối cùng
      if (_selectedItemIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedItemIds.add(id);
      
      // 🎯 Auto bật chế độ chọn khi click chọn từ đầu tiên
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  /// 🚀 CẬP NHẬT: Xóa toàn bộ lựa chọn & Reset mode
  void clearAllSelection() {
    _selectedItemIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  /// Áp dụng Debounce 300ms cho hàm search
  void search(String query) {
    _debounceTimer?.cancel(); // Hủy timer cũ nếu người dùng còn đang gõ
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _applyFilter();
      notifyListeners(); // Chỉ rebuild UI sau khi người dùng ngừng gõ 300ms
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

  // Hủy Timer khi Controller bị hủy để tránh leak bộ nhớ
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}