
class StreakData {
  final int currentExp;
  final int targetExp;
  final int streakDays;
  final int streakFreezeCount;
  final int availableChests;
  final double milestoneProgress; // 0.0 - 1.0
  final List<double> weeklyGrowthData; // Line / Bar chart data
  final List<Map<String, dynamic>> topVocabList; // Table data
  final List<int> heatmapDailyActivity; // Heatmap level (0 - 4)

  StreakData({
    required this.currentExp,
    required this.targetExp,
    required this.streakDays,
    required this.streakFreezeCount,
    required this.availableChests,
    required this.milestoneProgress,
    required this.weeklyGrowthData,
    required this.topVocabList,
    required this.heatmapDailyActivity,
  });
}

class FakeStreakRepository {
  Future<StreakData> fetchStreakData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return StreakData(
      currentExp: 380,
      targetExp: 500,
      streakDays: 14,
      streakFreezeCount: 2,
      availableChests: 1,
      milestoneProgress: 0.7,
      // Dữ liệu tăng trưởng 7 ngày (EXP)
      weeklyGrowthData: [120, 200, 150, 320, 450, 380, 500],
      // Dữ liệu danh sách từ vựng Mastery cao nhất
      topVocabList: [
        {'word': 'Persistent', 'level': 'C1', 'mastery': 98, 'count': 42},
        {'word': 'Resilient', 'level': 'B2', 'mastery': 95, 'count': 38},
        {'word': 'Substantial', 'level': 'B2', 'mastery': 91, 'count': 30},
        {'word': 'Endeavor', 'level': 'C2', 'mastery': 88, 'count': 25},
        {'word': 'Cognitive', 'level': 'C2', 'mastery': 85, 'count': 21},
        {'word': 'Encapsulation', 'level': 'B2', 'mastery': 82, 'count': 19},
        {'word': 'Polymorphism', 'level': 'C1', 'mastery': 80, 'count': 17},
      ],
      // Dữ liệu Heatmap cày level 28 ngày (0: nghỉ, 1: ít, 2: vừa, 3: chăm, 4: hardcore)
      heatmapDailyActivity: [
        2, 3, 1, 4, 0, 2, 3,
        1, 2, 4, 3, 2, 1, 0,
        3, 4, 2, 3, 4, 1, 2,
        0, 2, 3, 4, 3, 2, 4,
      ],
    );
  }
}