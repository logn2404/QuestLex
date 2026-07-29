import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/models/inventory_vocab_item.dart';
import '../domain/repositories/inventory_vocab_repository.dart';

enum SortOption {
  alphabetAsc,   // A -> Z
  alphabetDesc,  // Z -> A
  difficultyAsc, // Easy -> Hard (A1 -> C2)
  difficultyDesc,// Hard -> Easy (C2 -> A1)
}

class InventoryController extends ChangeNotifier {
  final InventoryVocabRepository _repository;

  List<InventoryVocabItem> _allVocab = [];
  List<InventoryVocabItem> _displayVocab = [];
  
  bool _isLoading = false;
  String _searchQuery = '';
  SortOption _selectedSort = SortOption.alphabetAsc;

  // Debounce Timer xử lý chống giật lag khi gõ search
  Timer? _debounceTimer;

  List<InventoryVocabItem> get vocabList => _displayVocab;
  bool get isLoading => _isLoading;
  SortOption get selectedSort => _selectedSort;

  InventoryController({required InventoryVocabRepository repository})
      : _repository = repository {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _allVocab = await _repository.getMasteredVocab();
    _applyFilterAndSort();

    _isLoading = false;
    notifyListeners();
  }

  // Xử lý Search với Debounce (300ms)
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _applyFilterAndSort();
      notifyListeners();
    });
  }

  // Đổi kiểu Sort
  void setSortOption(SortOption option) {
    _selectedSort = option;
    _applyFilterAndSort();
    notifyListeners();
  }

  void _applyFilterAndSort() {
    // 1. Filter theo query
    List<InventoryVocabItem> temp = _allVocab.where((item) {
      final q = _searchQuery.toLowerCase().trim();
      if (q.isEmpty) return true;
      return item.word.toLowerCase().contains(q) ||
          item.meaning.toLowerCase().contains(q);
    }).toList();

    // 2. Sort dữ liệu
    switch (_selectedSort) {
      case SortOption.alphabetAsc:
        temp.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
        break;
      case SortOption.alphabetDesc:
        temp.sort((a, b) => b.word.toLowerCase().compareTo(a.word.toLowerCase()));
        break;
      case SortOption.difficultyAsc:
        temp.sort((a, b) => a.difficultyWeight.compareTo(b.difficultyWeight));
        break;
      case SortOption.difficultyDesc:
        temp.sort((a, b) => b.difficultyWeight.compareTo(a.difficultyWeight));
        break;
    }

    _displayVocab = temp;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}