import '../../domain/models/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

class FakeDashboardRepository implements DashboardRepository {
  @override
  DashboardStats getDashboardStats() {
    return const DashboardStats(
      totalVocab: 1250,
      addedVocab: 320,
      learningVocab: 1250,
      masterChange: -20,
      pendingVocab: 32,
      streakDays: 5,
    );
  }
}