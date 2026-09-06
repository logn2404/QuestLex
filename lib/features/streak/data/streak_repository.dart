class StreakData {
  final int currentExp;
  final int targetExp;
  final int streakDays;
  final int streakFreezeCount;
  final int availableChests;
  final double milestoneProgress;
  final List<int> heatmapDailyActivity;
  final List<int> heatmapWordReviews;

  StreakData({
    required this.currentExp,
    required this.targetExp,
    required this.streakDays,
    required this.streakFreezeCount,
    required this.availableChests,
    required this.milestoneProgress,
    required this.heatmapDailyActivity,
    this.heatmapWordReviews = const [],
  });
}

abstract class StreakRepository {
  Future<StreakData> fetchStreakData();
}