import 'package:flutter/material.dart';
import '../../domain/enums/study_mode.enum.dart';

class StudyHeaderBanner extends StatelessWidget {
  final StudyMode mode;
  final bool isGoldenHour;
  final double expMultiplier;
  final int wordCount; // Thêm tham số đếm số từ

  const StudyHeaderBanner({
    super.key,
    required this.mode,
    required this.isGoldenHour,
    required this.expMultiplier,
    required this.wordCount,
  });

  @override
  Widget build(BuildContext context) {
    final isStudy = mode == StudyMode.study;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isStudy
              ? [const Color(0xFF380A0A), const Color(0xFF1E1E24)]
              : [const Color(0xFF0F1E15), const Color(0xFF1E1E24)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStudy ? Colors.redAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isStudy ? Icons.bolt_rounded : Icons.security_rounded,
            color: isStudy ? Colors.amber : Colors.greenAccent,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStudy
                      ? (isGoldenHour ? '🔥 GIỜ VÀNG (BUFF x$expMultiplier EXP)' : '🗡️ CHẾ ĐỘ STUDY')
                      : '🛡️ CHẾ ĐỘ PRACTICE (SINH TỒN)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                // 🎯 DÒNG THÔNG BÁO TỪ VỰNG TẢI NGẦM
                Text(
                  wordCount > 0 
                      ? '⚔️ Có $wordCount từ vựng đang chờ bạn chinh phục!'
                      : '⏳ Đang tải từ vựng...',
                  style: TextStyle(color: isStudy ? Colors.redAccent.shade100 : Colors.greenAccent.shade100, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}