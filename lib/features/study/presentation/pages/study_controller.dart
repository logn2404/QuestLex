import 'package:flutter/material.dart';
import '../../data/repositories/api_study_repositories.dart';
import '../../domain/enums/study_mode.enum.dart';

class StudyController extends ChangeNotifier {
  final ApiStudyRepository _repository;

  List<Map<String, dynamic>> _studyQueue = [];
  StudyMode _currentMode = StudyMode.study;
  bool _isLoading = false;

  // Giả lập trạng thái Giờ Vàng
  final bool isGoldenHour = true;
  final double expMultiplier = 1.5;

  List<Map<String, dynamic>> get studyQueue => _studyQueue;
  StudyMode get currentMode => _currentMode;
  bool get isLoading => _isLoading;
  int get wordCount => _studyQueue.length;

  StudyController({
    required ApiStudyRepository repository,
    List<Map<String, dynamic>> initialWords = const [],
  }) : _repository = repository {
    if (initialWords.isNotEmpty) {
      _studyQueue = List.from(initialWords);
    } else {
      loadStudyWords();
    }
  }

  void setMode(StudyMode mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    loadStudyWords();
  }

  Future<void> loadStudyWords() async {
    _isLoading = true;
    notifyListeners();

    _studyQueue = await _repository.getStudyWords(
      limit: 30,
      mode: _currentMode == StudyMode.study ? 'study' : 'practice',
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> reviewWord(String word, int quality) async {
    await _repository.reviewWord(word, quality);
  }
}