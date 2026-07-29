import 'package:flutter/material.dart';

class MonthlyDiffBadge extends StatelessWidget {
  final int diff;

  const MonthlyDiffBadge({super.key, required this.diff});

  @override
  Widget build(BuildContext context) {
    if (diff == 0) return const SizedBox.shrink();

    final isPositive = diff > 0;
    final color = isPositive ? Colors.greenAccent : Colors.redAccent;
    final sign = isPositive ? '+' : '';

    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.white),
        children: [
          const TextSpan(text: ' ('),
          TextSpan(
            text: '$sign$diff',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(text: ')'),
        ],
      ),
    );
  }
}