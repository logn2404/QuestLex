import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/repositories/api_study_repositories.dart';
import '../../domain/enums/study_mode.enum.dart';

class StudyController extends ChangeNotifier {
  final ApiStudyRepository _repository;

  List<Map<String, dynamic>> _studyQueue = [];
  StudyMode _currentMode = StudyMode.study;
  bool _isLoading = false;
  Timer? _autoRefreshTimer;
  bool _isDisposed = false;

  final bool isGoldenHour = true;
  final double expMultiplier = 1.5;

  List<Map<String, dynamic>> get studyQueue => _studyQueue;
  StudyMode get currentMode => _currentMode;
  bool get isLoading => _isLoading;
  int get wordCount => _studyQueue.length;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  StudyController({
    required this._repository,
    List<Map<String, dynamic>> initialWords = const [],
  }) {
    if (initialWords.isNotEmpty) {
      _studyQueue = List.from(initialWords);
    } else {
      loadStudyWords();
    }
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadStudyWords(isSilent: true);
    });
  }

  void setMode(StudyMode mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    loadStudyWords();
  }

  Future<void> loadStudyWords({bool isSilent = false}) async {
    if (_isDisposed) return;

    if (!isSilent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final fetchedQueue = await _repository.getStudyWords(
        limit: 30,
        mode: _currentMode == StudyMode.study ? 'study' : 'practice',
      );
      if (_isDisposed) return;
      _studyQueue = fetchedQueue;
    } catch (e) {
      debugPrint('⚠️ Auto-refresh Study Words Error: $e');
    } finally {
      if (!isSilent) _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> reviewWord(String word, int quality) async {
    await _repository.reviewWord(word, quality);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}