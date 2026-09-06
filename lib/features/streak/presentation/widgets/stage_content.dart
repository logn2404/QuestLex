import 'package:flutter/material.dart';
import '../../data/streak_repository.dart';
import '../streak_controller.dart';

class StageContent extends StatelessWidget {
  final StreakController controller;

  const StageContent({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final data = controller.streakData!;
    return _buildStreakHeatmap(data);
  }

  Widget _buildStreakHeatmap(StreakData data) {
    final weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Streak Heatmap (28 ngày)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Nhãn thứ căn đúng theo 7 cột của heatmap.
        Row(
          children: weekDays.map((day) {
            return Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Mỗi cột tương ứng một thứ; dữ liệu đi theo thứ tự từ T2 đến CN.
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: data.heatmapDailyActivity.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final level = data.heatmapDailyActivity[index];
              final wordReviews = index < data.heatmapWordReviews.length
                  ? data.heatmapWordReviews[index]
                  : 0;
              final color = level == 0
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.orange.withValues(alpha: 0.25 * level);

              return Tooltip(
                message: '$wordReviews từ đã học',
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: level > 0 ? Colors.orangeAccent : Colors.white12,
                      width: 0.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}