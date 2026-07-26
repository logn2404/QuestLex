import '../../domain/models/daily_cefr_count.dart';
import '../../domain/models/learning_vocab_item.dart';
import '../../domain/repositories/learning_vocab_repository.dart';

class FakeLearningVocabRepository implements LearningVocabRepository {
  @override
  Future<List<LearningVocabItem>> getLearningVocab() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Giả lập độ trễ mạng/database
    return const [
      LearningVocabItem(
        id: '1',
        word: 'Algorithm',
        meaning: 'Thuật toán',
        cefrLevel: 'B2',
        currentProgress: 99,
      ),
      LearningVocabItem(
        id: '2',
        word: 'Refactor',
        meaning: 'Tối ưu/Sửa cấu trúc code',
        cefrLevel: 'C1',
        currentProgress: 75,
      ),
      LearningVocabItem(
        id: '3',
        word: 'Architecture',
        meaning: 'Kiến trúc',
        cefrLevel: 'B1',
        currentProgress: 40,
      ),
      LearningVocabItem(
        id: '4',
        word: 'Optimization',
        meaning: 'Sự tối ưu hóa',
        cefrLevel: 'C2',
        currentProgress: 88,
      ),
      LearningVocabItem(
        id: '5',
        word: 'Encapsulation',
        meaning: 'Đóng gói (trong lập trình hướng đối tượng)',
        cefrLevel: 'B2',
        currentProgress: 60,
      ),
      LearningVocabItem(
        id: '6',
        word: 'Polymorphism',
        meaning: 'Đa hình (trong lập trình hướng đối tượng)',
        cefrLevel: 'C1',
        currentProgress: 30,
      ),
      LearningVocabItem(
        id: '7',
        word: 'Abstraction',
        meaning: 'Trừu tượng hóa (trong lập trình hướng đối tượng)',
        cefrLevel: 'B1',
        currentProgress: 50,
      ),
      LearningVocabItem(
        id: '8',
        word: 'Concurrency',
        meaning: 'Đồng thời (trong lập trình)',
        cefrLevel: 'C2',
        currentProgress: 20,
      ),
      LearningVocabItem(
        id: '9',
        word: 'Dependency Injection',
        meaning: 'Tiêm phụ thuộc (trong lập trình)',
        cefrLevel: 'C1',
        currentProgress: 10,
      ),
      LearningVocabItem(
        id: '10',
        word: 'Microservices',
        meaning: 'Kiến trúc vi dịch vụ',
        cefrLevel: 'B2',
        currentProgress: 5,
      ),
      LearningVocabItem(
        id: '11',
        word: 'Singleton',
        meaning: 'Mẫu thiết kế Singleton',
        cefrLevel: 'B1',
        currentProgress: 15,
      ),
      LearningVocabItem(
        id: '12',
        word: 'Observer Pattern',
        meaning: 'Mẫu thiết kế Observer',
        cefrLevel: 'C1',
        currentProgress: 25,
      ),
      LearningVocabItem(
        id: '13',
        word: 'Factory Pattern',
        meaning: 'Mẫu thiết kế Factory',
        cefrLevel: 'B2',
        currentProgress: 35,
      ),
      LearningVocabItem(
        id: '14',
        word: 'Builder Pattern',
        meaning: 'Mẫu thiết kế Builder',
        cefrLevel: 'C1',
        currentProgress: 45,
      ),
      LearningVocabItem(
        id: '15',
        word: 'Adapter Pattern',
        meaning: 'Mẫu thiết kế Adapter',
        cefrLevel: 'B1',
        currentProgress: 55,
      ),
      LearningVocabItem(
        id: '16',
        word: 'Strategy Pattern',
        meaning: 'Mẫu thiết kế Strategy',
        cefrLevel: 'C2',
        currentProgress: 65,
      ),
      LearningVocabItem(
        id: '17',
        word: 'Decorator Pattern',
        meaning: 'Mẫu thiết kế Decorator',
        cefrLevel: 'B2',
        currentProgress: 75,
      ),
      LearningVocabItem(
        id: '18',
        word: 'Command Pattern',
        meaning: 'Mẫu thiết kế Command',
        cefrLevel: 'C1',
        currentProgress: 85,
      ),
    ];
  }

  @override
  Future<List<DailyCEFRCount>> getDailyStats() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const [
      DailyCEFRCount(label: 'T2', countsByLevel: {'A1': 2, 'A2': 3, 'B1': 1}),
      DailyCEFRCount(label: 'T3', countsByLevel: {'A2': 1, 'B1': 4, 'B2': 2}),
      DailyCEFRCount(label: 'T4', countsByLevel: {'B1': 2, 'B2': 3, 'C1': 1}),
      DailyCEFRCount(label: 'T5', countsByLevel: {'A1': 1, 'B2': 2, 'C2': 1}),
      DailyCEFRCount(label: 'T6', countsByLevel: {'B2': 5, 'C1': 2}),
      DailyCEFRCount(label: 'T7', countsByLevel: {'A2': 2, 'B1': 3, 'B2': 4}),
      DailyCEFRCount(label: 'CN', countsByLevel: {'B1': 1, 'B2': 2, 'C1': 8}),
    ];
  }

  @override
  Future<List<DailyCEFRCount>> getMonthlyStats() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const [
      DailyCEFRCount(label: 'Jan', countsByLevel: {'A1': 10, 'A2': 15, 'B1': 8}),
      DailyCEFRCount(label: 'Feb', countsByLevel: {'A2': 8, 'B1': 20, 'B2': 12}),
      DailyCEFRCount(label: 'Mar', countsByLevel: {'B1': 15, 'B2': 25, 'C1': 10}),
      DailyCEFRCount(label: 'Apr', countsByLevel: {'B2': 18, 'C1': 14, 'C2': 5}),
    ];
  }
}