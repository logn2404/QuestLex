import 'package:flutter/material.dart';
import 'package:questlex/features/learning_vocab/domain/models/vocab_stats.dart';

class Profile extends StatelessWidget {
  final VocabStats stats;

  const Profile({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. VÒNG TRÒN LEVEL & EXP PROGRESS
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: stats.expProgressRatio,
                        strokeWidth: 8,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: Colors.greenAccent,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${stats.calculatedLevel}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'LVL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. ĐÁNH GIÁ CEFR STAR RATING (6 Ngôi sao tương ứng 6 bậc)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(6, (index) {
                    final double starScore = stats.totalStars - index;
                    IconData iconData = Icons.star_border_rounded;
                    Color iconColor = Colors.amber.withValues(alpha: 0.4);

                    if (starScore >= 0.8) {
                      iconData = Icons.star_rounded;
                      iconColor = Colors.amber;
                    } else if (starScore >= 0.3) {
                      iconData = Icons.star_half_rounded;
                      iconColor = Colors.amber;
                    }

                    return Icon(iconData, color: iconColor, size: 22);
                  }),
                  const SizedBox(width: 6),
                  Text(
                    '${stats.totalStars}/6',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // 3. THỐNG KÊ SỐ TỪ THEO LEVEL CEFR
              ...['C2', 'C1', 'B2', 'B1', 'A2', 'A1'].map((level) {
                final count = stats.levelCounts[level] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        level,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$count từ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}