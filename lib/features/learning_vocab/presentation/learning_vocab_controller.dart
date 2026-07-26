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

  List<LearningVocabItem> get vocabList => _filteredVocab;
  List<DailyCEFRCount> get dailyStats => _dailyStats;
  List<DailyCEFRCount> get monthlyStats => _monthlyStats;
  Set<String> get selectedItemIds => _selectedItemIds;
  bool get isSelectionMode => _isSelectionMode;
  double get leftPanelWidth => _leftPanelWidth;
  bool get isLoading => _isLoading;

  // Constructor nhận repository
  LearningVocabController({required LearningVocabRepository repository})
      : _repository = repository {
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

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedItemIds.clear();
    }
    notifyListeners();
  }

  void toggleSelectItem(String id) {
    if (_selectedItemIds.contains(id)) {
      _selectedItemIds.remove(id);
    } else {
      _selectedItemIds.add(id);
    }
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
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
}