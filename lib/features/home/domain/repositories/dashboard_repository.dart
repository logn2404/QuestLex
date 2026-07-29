import '../models/dashboard_stats.dart';


abstract class DashboardRepository {
  Future<DashboardStats> getDashboardStats();
}