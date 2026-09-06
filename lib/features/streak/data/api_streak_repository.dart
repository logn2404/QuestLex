import '../../../services/questlex_api_client.dart';
import 'streak_repository.dart';

class ApiStreakRepository implements StreakRepository {
  final QuestLexApiClient _apiClient;

  ApiStreakRepository({QuestLexApiClient? apiClient})
      : _apiClient = apiClient ?? const QuestLexApiClient();

  @override
  Future<StreakData> fetchStreakData() async {
    final data = await _apiClient.getJson('streak');
    if (data == null || data['success'] != true) {
      throw StateError('Không thể tải dữ liệu streak từ backend.');
    }

    final activity = data['heatmapDailyActivity'];
    final wordReviews = data['heatmapWordReviews'];
    return StreakData(
      currentExp: (data['currentExp'] as num?)?.toInt() ?? 0,
      targetExp: (data['targetExp'] as num?)?.toInt() ?? 500,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      streakFreezeCount: (data['streakFreezeCount'] as num?)?.toInt() ?? 0,
      availableChests: (data['availableChests'] as num?)?.toInt() ?? 0,
      milestoneProgress: (data['milestoneProgress'] as num?)?.toDouble() ?? 0,
      heatmapDailyActivity: activity is List
          ? activity.map((value) => (value as num).toInt()).toList()
          : const <int>[],
        heatmapWordReviews: wordReviews is List
          ? wordReviews.map((value) => (value as num).toInt()).toList()
          : const <int>[],
    );
  }
}