import '../models/daily_cefr_count.dart';
import '../models/learning_vocab_item.dart';

class TrendAnalyzer {
  /// 📈 Phân tích dữ liệu theo các Ngày trong tuần (Mon -> Sun)
  static List<DailyCEFRCount> analyzeDailyStats(List<LearningVocabItem> vocabList) {
    // Khởi tạo Map với các phím tiếng Anh
    final Map<String, Map<String, int>> daysMap = {
      'Mon': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Tue': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Wed': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Thu': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Fri': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Sat': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Sun': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
    };

    const dayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (var item in vocabList) {
      // DateTime.weekday: 1 (Mon) -> 7 (Sun)
      final weekdayIndex = item.createdAt.weekday - 1; 
      if (weekdayIndex >= 0 && weekdayIndex < dayKeys.length) {
        final dayLabel = dayKeys[weekdayIndex];
        final level = item.cefrLevel.toUpperCase();
        if (daysMap[dayLabel]!.containsKey(level)) {
          daysMap[dayLabel]![level] = daysMap[dayLabel]![level]! + 1;
        }
      }
    }

    return dayKeys
        .map((label) => DailyCEFRCount(label: label, countsByLevel: daysMap[label]!))
        .toList();
  }

  /// 📊 Phân tích dữ liệu theo các Tháng trong năm (Jan -> Dec)
  static List<DailyCEFRCount> analyzeMonthlyStats(List<LearningVocabItem> vocabList) {
    final Map<String, Map<String, int>> monthsMap = {
      'Jan': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Feb': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Mar': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Apr': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'May': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Jun': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Jul': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Aug': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Sep': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Oct': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Nov': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
      'Dec': {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0, 'C1': 0, 'C2': 0},
    };

    const monthKeys = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    for (var item in vocabList) {
      // DateTime.month: 1 (Jan) -> 12 (Dec)
      final monthIndex = item.createdAt.month - 1; 
      if (monthIndex >= 0 && monthIndex < monthKeys.length) {
        final monthLabel = monthKeys[monthIndex];
        final level = item.cefrLevel.toUpperCase();
        if (monthsMap[monthLabel]!.containsKey(level)) {
          monthsMap[monthLabel]![level] = monthsMap[monthLabel]![level]! + 1;
        }
      }
    }

    return monthKeys
        .map((label) => DailyCEFRCount(label: label, countsByLevel: monthsMap[label]!))
        .toList();
  }
}