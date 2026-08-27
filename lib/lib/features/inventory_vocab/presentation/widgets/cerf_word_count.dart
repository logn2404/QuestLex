import 'package:flutter/material.dart';

class CerfWordCount extends StatelessWidget {
  final Map<String, int> levelCounts;

  const CerfWordCount({
    super.key,
    required this.levelCounts,
  });

  @override
  Widget build(BuildContext context) {
    const levels = ['C2', 'C1', 'B2', 'B1', 'A2', 'A1'];
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: levels.map((level) {
        int count = levelCounts[level] ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                level,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                count > 0 ? '$count từ' : '-',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}