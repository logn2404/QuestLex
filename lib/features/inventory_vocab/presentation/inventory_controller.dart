import 'dart:async';
import 'package:flutter/material.dart';
import 'package:questlex/features/learning_vocab/domain/models/vocab_stats.dart';
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

  Timer? _debounceTimer;

  List<InventoryVocabItem> get vocabList => _displayVocab;
  bool get isLoading => _isLoading;
  SortOption get selectedSort => _selectedSort;

  // 🎯 TÍNH TOÁN CÁC CHỈ SỐ CEFR ĐỘNG (Dùng cho Profile)
  VocabStats get stats {
    final Map<String, int> counts = {
      'C2': 0, 'C1': 0, 'B2': 0, 'B1': 0, 'A2': 0, 'A1': 0,
    };
    for (var item in _allVocab) {
      final level = item.cefrLevel.toUpperCase();
      if (counts.containsKey(level)) {
        counts[level] = counts[level]! + 1;
      }
    }
    return VocabStats(levelCounts: counts);
  }

  InventoryController({required this._repository}) {
    loadData();
  }

  // 🛠️ FIX: Bổ sung try-catch và log để kiểm tra dữ liệu thật từ API
  Future<void> loadData() async {
    _isLoading = true;
    // Thông báo trạng thái loading cho UI
    Future.microtask(() => notifyListeners()); 

    try {
      debugPrint('📡 [InventoryController]: Đang gọi API lấy kho từ vựng...');
      _allVocab = await _repository.getMasteredVocab();
      
      debugPrint('✅ [InventoryController]: Đã nạp thành công ${_allVocab.length} từ.');
      
      // Áp dụng bộ lọc và sắp xếp ngay sau khi lấy dữ liệu về
      _applyFilterAndSort();
    } catch (e) {
      debugPrint('❌ [InventoryController Error]: Không thể tải dữ liệu: $e');
      _allVocab = [];
      _displayVocab = [];
      // Bạn có thể quăng lỗi ra để Page bắt và hiện Dialog nếu muốn
      rethrow; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    debugPrint('🔍 [InventoryController]: Đang hiển thị ${_displayVocab.length} từ.');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}