import '../../domain/models/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

class FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardStats> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const DashboardStats(
      totalInventoryVocab: 1250,
      inventoryMonthlyDiff: 320,  // Tăng 320 từ so với tháng trước
      totalLearningVocab: 1250,
      learningMonthlyDiff: -20,   // Giảm 20 từ so me với tháng trước
      pendingVocab: 15,
      streakDays: 7,
    );
  }
}