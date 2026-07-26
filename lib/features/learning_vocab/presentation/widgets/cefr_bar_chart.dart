import 'package:flutter/material.dart';
import '../../domain/models/daily_cefr_count.dart';

class CefrBarChart extends StatelessWidget {
  final List<DailyCEFRCount> data;

  const CefrBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Tông màu đậm nhạt tăng dần theo trình độ CEFR từ A1 -> C2 (Dùng withValues chuẩn Flutter mới)
    final Map<String, Color> cefrShades = {
      'A1': primaryColor.withValues(alpha: 0.25),
      'A2': primaryColor.withValues(alpha: 0.40),
      'B1': primaryColor.withValues(alpha: 0.55),
      'B2': primaryColor.withValues(alpha: 0.70),
      'C1': primaryColor.withValues(alpha: 0.85),
      'C2': primaryColor,
    };

    final maxCount = data.fold<int>(1, (max, item) => item.total > max ? item.total : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Danh sách các thanh Bar ngang
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = data[index];
            final widthFactor = (item.total / maxCount).clamp(0.02, 1.0);

            return Row(
              children: [
                // 1. Nhãn thời gian (T2, T3... / Jan, Feb...)
                SizedBox(
                  width: 32,
                  child: Text(
                    item.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Thanh Bar ngang tự dãn 100% theo chiều rộng Cột Trái
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Chừa khoảng 28px cho Text hiển thị tổng số từ ở bên phải thanh bar
                      final availableWidth = constraints.maxWidth - 28;
                      final barWidth = (availableWidth * widthFactor).clamp(4.0, availableWidth);

                      return Row(
                        children: [
                          Container(
                            height: 16,
                            width: barWidth,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              children: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'].map((level) {
                                int count = item.countsByLevel[level] ?? 0;
                                if (count == 0) return const SizedBox.shrink();

                                return Container(
                                  width: (count / (item.total > 0 ? item.total : 1)) * barWidth,
                                  color: cefrShades[level],
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tổng số từ
                          Text(
                            '${item.total}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Chú thích (Legend)
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: cefrShades.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: entry.value,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  entry.key,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}