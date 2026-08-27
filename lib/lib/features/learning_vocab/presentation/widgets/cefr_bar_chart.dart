import 'package:flutter/material.dart';
import '../../domain/models/daily_cefr_count.dart';

class CefrBarChart extends StatelessWidget {
  final List<DailyCEFRCount> data;
  const CefrBarChart({super.key, required this.data});

  static const Map<String, Color> cefrColors = {
    'A1': Color(0xFF32284C), 'A2': Color(0xFF4A3B6B),
    'B1': Color(0xFF6750A4), 'B2': Color(0xFF8F76D6),
    'C1': Color(0xFFB69DF8), 'C2': Color(0xFFD0BCFF),
  };

  @override
  Widget build(BuildContext context) {
    int maxTotal = 0;
    for (var item in data) {
      int total = item.countsByLevel.values.fold(0, (sum, c) => sum + c);
      if (total > maxTotal) maxTotal = total;
    }
    if (maxTotal == 0) maxTotal = 1;

    return Column(
      mainAxisSize: MainAxisSize.min, // Giới hạn chiều cao Column
      children: [
        ListView.separated(
          shrinkWrap: true, // 🛠️ QUAN TRỌNG: Fix lỗi Unbounded Height
          physics: const NeverScrollableScrollPhysics(), // Dùng cuộn của trang chính
          padding: EdgeInsets.zero,
          itemCount: data.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = data[index];
            int total = item.countsByLevel.values.fold(0, (sum, c) => sum + c);
            return Row(
              children: [
                SizedBox(width: 32, child: Text(item.label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                SizedBox(width: 24, child: Text('$total', style: const TextStyle(color: Colors.white54, fontSize: 11))),
                const SizedBox(width: 6),
                Expanded( // Expanded ở đây hợp lệ vì nằm trong Row có kích thước ngang
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 14,
                      child: CustomPaint(painter: CefrBarPainter(countsByLevel: item.countsByLevel, maxTotal: maxTotal)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: cefrColors.entries.map((e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: e.value, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(e.key, style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ],
      )).toList(),
    );
  }
}

class CefrBarPainter extends CustomPainter {
  final Map<String, int> countsByLevel;
  final int maxTotal;

  CefrBarPainter({required this.countsByLevel, required this.maxTotal});

  @override
  void paint(Canvas canvas, Size size) {
    int total = countsByLevel.values.fold(0, (sum, c) => sum + c);

    if (total == 0) {
      final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.04);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(4),
        ),
        bgPaint,
      );
      return;
    }

    double currentX = 0;
    double barWidthRatio = (total / maxTotal).clamp(0.05, 1.0);
    double availableWidth = size.width * barWidthRatio;

    countsByLevel.forEach((level, count) {
      if (count > 0) {
        double segmentWidth = (count / total) * availableWidth;
        final paint = Paint()
          ..color = CefrBarChart.cefrColors[level] ?? const Color(0xFF6750A4);

        canvas.drawRect(
          Rect.fromLTWH(currentX, 0, segmentWidth, size.height),
          paint,
        );
        currentX += segmentWidth;
      }
    });
  }

  @override
  bool shouldRepaint(covariant CefrBarPainter oldDelegate) {
    return oldDelegate.countsByLevel != countsByLevel ||
        oldDelegate.maxTotal != maxTotal;
  }
}