import 'package:flutter/material.dart';

/// Class tập trung các Custom Icon cho QuestLex
class CustomIcon extends StatelessWidget {
  final Widget child;

  const CustomIcon._({
    super.key,
    required this.child,
  });

  /// 🎴 Icon Thẻ Bài Học Tập / Flashcards (Theme Đỏ - Đen BẮT ĐẦU HỌC)
  factory CustomIcon.swordShield({double size = 32.0, Key? key}) {
    return CustomIcon._(
      key: key,
      child: SizedBox(
        width: size * 1.3,
        height: size * 1.3,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Hiệu ứng đệm nền phát sáng đỏ thẫm đằng sau
            Container(
              width: size * 0.95,
              height: size * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB71C1C).withValues(alpha: 0.25), // Red 900
              ),
            ),

            // 2. Icon Bộ bài tây (Playing Cards) màu đỏ rực rỡ
            Icon(
              Icons.style,
              size: size * 1.0,
              color: const Color(0xFFE53935), // Đỏ tươi Red 600
            ),

            // 3. Điểm nhấn ngôi sao phát sáng nhỏ ở góc bài
            Positioned(
              top: size * 0.1,
              right: size * 0.1,
              child: Icon(
                Icons.auto_awesome,
                size: size * 0.4,
                color: Colors.amberAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}