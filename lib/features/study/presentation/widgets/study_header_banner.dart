import 'package:flutter/material.dart';
import 'package:questlex/features/study/domain/enums/study_mode.enum.dart';

class StudyHeaderBanner extends StatelessWidget {
  final StudyMode mode;
  final bool isGoldenHour;
  final double expMultiplier;

  const StudyHeaderBanner({
    super.key,
    required this.mode,
    this.isGoldenHour = false,
    this.expMultiplier = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return mode == StudyMode.study
        ? _buildStudyBanner()
        : _buildPracticeBanner();
  }

  Widget _buildStudyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFB71C1C).withValues(alpha: 0.3), Colors.black54],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGoldenHour ? Colors.amber.shade700 : const Color(0xFFB71C1C),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGoldenHour ? Colors.amber.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGoldenHour ? Icons.access_time_filled_rounded : Icons.menu_book_rounded,
              color: isGoldenHour ? Colors.amber : Colors.redAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isGoldenHour ? '🔥 GIỜ VÀNG TẬP TRUNG' : 'CHẾ ĐỘ HỌC ĐẠT EXP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isGoldenHour ? Colors.amber : Colors.white,
                      ),
                    ),
                    if (isGoldenHour) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BUFF x${expMultiplier.toStringAsFixed(1)} EXP',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isGoldenHour
                      ? 'Đang trong khung giờ vàng! Hoàn thành bài học ngay để nhận gấp đôi EXP.'
                      : 'Học bài mới để mở khóa Mastery và tích lũy EXP tăng cấp.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.shade900.withValues(alpha: 0.4), Colors.black54],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepOrangeAccent),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚡ THỬ THÁCH SINH TỒN VÔ HẠN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ưu tiên từ có điểm Mastery thấp. Trả lời đúng nhận Mastery & EXP liên tục. Sai 1 câu dừng Session!',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}