import 'package:flutter/material.dart';
import '../../domain/models/daily_cefr_count.dart';
import 'cefr_bar_chart.dart';

enum TimePeriod { day, month }

class LearningAnalytics extends StatefulWidget {
  final List<DailyCEFRCount> dailyData;
  final List<DailyCEFRCount> monthlyData;

  const LearningAnalytics({
    super.key,
    required this.dailyData,
    required this.monthlyData,
  });

  @override
  State<LearningAnalytics> createState() => _LearningAnalyticsState();
}

class _LearningAnalyticsState extends State<LearningAnalytics> {
  TimePeriod _selectedPeriod = TimePeriod.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity, // Tự dãn 100% theo cột trái
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header & Toggle Ngày / Tháng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Tiêu đề (Bọc Expanded để co dãn linh hoạt, không đẩy đụng SegmentedButton)
                  Expanded(
                    child: Text(
                      'Tiến độ học tập',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Nút chuyển Ngày/Tháng thu gọn padding
                  SizedBox(
                    height: 32,
                    child: SegmentedButton<TimePeriod>(
                      segments: const [
                        ButtonSegment(
                          value: TimePeriod.day,
                          label: Text('Ngày', style: TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: TimePeriod.month,
                          label: Text('Tháng', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                      selected: {_selectedPeriod},
                      onSelectionChanged: (Set<TimePeriod> newSelection) {
                        setState(() {
                          _selectedPeriod = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Bar Chart Ngang
              CefrBarChart(
                data: _selectedPeriod == TimePeriod.day
                    ? widget.dailyData
                    : widget.monthlyData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}