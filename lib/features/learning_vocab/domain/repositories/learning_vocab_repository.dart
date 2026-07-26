import '../models/daily_cefr_count.dart';
import '../models/learning_vocab_item.dart';

abstract class LearningVocabRepository {
  Future<List<LearningVocabItem>> getLearningVocab();
  Future<List<DailyCEFRCount>> getDailyStats();
  Future<List<DailyCEFRCount>> getMonthlyStats();
}