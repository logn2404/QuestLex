import 'package:flutter/material.dart';
import '../../data/fake_streak_repository.dart';
import '../streak_controller.dart';

class StageContent extends StatelessWidget {
  final StreakController controller;

  const StageContent({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final data = controller.streakData!;

    switch (controller.currentMode) {
      case StreakViewMode.growthChart:
        return _buildGrowthChart(data);

      case StreakViewMode.topVocabTable:
        return _buildTopVocabTable(data);

      case StreakViewMode.activityHeatmap:
        return _buildActivityHeatmap(data);
    }
  }

  // 🎯 1. BIỂU ĐỒ CÓ TRỤC Y KHỚP 100% CHIỀU CAO CỘT + ĐỘ ĐẬM THEO GIÁ TRỊ
  Widget _buildGrowthChart(StreakData data) {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final yAxisValues = [500, 375, 250, 125, 0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tốc độ tăng trưởng từ vựng (7 ngày gần nhất)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🟢 TRỤC TUNG (Y-AXIS)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: yAxisValues.map((val) {
                  return Text(
                    '$val',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  );
                }).toList(),
              ),
              const SizedBox(width: 12),

              // ĐƯỜNG KẺ TRỤC TUNG
              Container(width: 1, color: Colors.white12),
              const SizedBox(width: 12),

              // 🟢 KHU VỰC CỘT & TRỤC HOÀNH (X-AXIS)
              Expanded(
                child: Column(
                  children: [
                    // Các Cột dữ liệu (Dùng LayoutBuilder để tính chiều cao thực tế)
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Chiều cao tối đa dành cho phần cột (trừ bớt chỗ cho label số ở trên)
                          final maxBarHeight = constraints.maxHeight - 24;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(data.weeklyGrowthData.length, (index) {
                              final val = data.weeklyGrowthData[index];
                              final ratio = (val / 500.0).clamp(0.0, 1.0);
                              
                              // 🎨 Tính độ đậm màu cam theo giá trị (Thấp = nhạt, Cao = đậm rực)
                              final opacity = 0.35 + (0.65 * ratio);
                              final barColor = Colors.orangeAccent.withValues(alpha: opacity);

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${val.toInt()}',
                                    style: TextStyle(
                                      color: barColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 24,
                                    height: (maxBarHeight * ratio).clamp(4.0, maxBarHeight),
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orangeAccent.withValues(alpha: 0.4 * ratio),
                                          blurRadius: 8 * ratio,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          );
                        },
                      ),
                    ),

                    // ĐƯỜNG KẺ TRỤC HOÀNH
                    Container(height: 1, color: Colors.white12),
                    const SizedBox(height: 8),

                    // 🟢 TRỤC HOÀNH (X-AXIS): Thứ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(days.length, (index) {
                        return SizedBox(
                          width: 24,
                          child: Text(
                            days[index],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🎯 2. BẢNG TOP VOCAB
  Widget _buildTopVocabTable(StreakData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Từ vựng có điểm Mastery cao nhất',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: data.topVocabList.length,
            separatorBuilder: (_, _) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final item = data.topVocabList[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  item['word'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Đã ôn: ${item['count']} lần',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['level'],
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item['mastery']}%',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 🎯 3. BẢN ĐỒ HOẠT ĐỘNG (HEATMAP GRID NHỎ GỌN)
  Widget _buildActivityHeatmap(StreakData data) {
    final weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bản đồ hoạt động (Heatmap 28 ngày)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // NHÃN THỨ TRONG TUẦN
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: weekDays.map((day) {
            return Container(
              width: 32,
              margin: const EdgeInsets.only(right: 8),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // GRID Ô SQUARE NHỎ GỌN (32x32px)
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(data.heatmapDailyActivity.length, (index) {
                final level = data.heatmapDailyActivity[index];
                final color = level == 0
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.orange.withValues(alpha: 0.25 * level);

                return Tooltip(
                  message: 'Ngày ${index + 1}: Mức cày level $level',
                  child: Container(
                    width: 32,
                    height: 32,
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
              }),
            ),
          ),
        ),
      ],
    );
  }
}