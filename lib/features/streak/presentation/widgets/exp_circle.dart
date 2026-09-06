import 'package:flutter/material.dart';
import '../../data/streak_repository.dart';

class ExpCircle extends StatelessWidget {
  final StreakData data;

  const ExpCircle({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = data.currentExp >= data.targetExp;
    final double progress = (data.currentExp / data.targetExp).clamp(0.0, 1.0);

    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange.withValues(alpha: 0.08),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withValues(alpha: isCompleted ? 0.3 : 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 190,
            height: 190,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: Colors.white10,
              color: isCompleted ? Colors.greenAccent : Colors.orangeAccent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 40,
                  color: isCompleted ? Colors.greenAccent : Colors.orangeAccent,
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted
                      ? 'ĐÃ ĐẠT KPI!'
                      : '${data.currentExp} / ${data.targetExp} EXP',
                  style: TextStyle(
                    color: isCompleted ? Colors.greenAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Streak: ${data.streakDays} ngày',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}