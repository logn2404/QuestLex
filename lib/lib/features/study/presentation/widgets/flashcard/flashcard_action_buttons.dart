import 'package:flutter/material.dart';

class FlashcardActionButtons extends StatelessWidget {
  final Function(int quality) onReview;

  const FlashcardActionButtons({
    super.key,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Quên / Khó nhớ (Quality = 1)
        Expanded(
          child: _buildActionButton(
            label: 'QUÊN',
            subLabel: 'Tái học',
            color: const Color(0xFFFF5252),
            bgColor: const Color(0xFF2C1012),
            icon: Icons.close_rounded,
            onTap: () => onReview(1),
          ),
        ),
        const SizedBox(width: 8),

        // 2. Tạm nhớ / Hơi khó (Quality = 2)
        Expanded(
          child: _buildActionButton(
            label: 'KHÓ',
            subLabel: 'Hơi mơ hồ',
            color: const Color(0xFFFFB74D),
            bgColor: const Color(0xFF2A2010),
            icon: Icons.help_outline_rounded,
            onTap: () => onReview(2),
          ),
        ),
        const SizedBox(width: 8),

        // 3. Đúng / Nhớ tốt (Quality = 3)
        Expanded(
          child: _buildActionButton(
            label: 'ĐÚNG',
            subLabel: 'Nhớ rõ',
            color: const Color(0xFF66BB6A),
            bgColor: const Color(0xFF102818),
            icon: Icons.check_rounded,
            onTap: () => onReview(3),
          ),
        ),
        const SizedBox(width: 8),

        // 4. Dễ ợt / Thuộc lòng (Quality = 4)
        Expanded(
          child: _buildActionButton(
            label: 'RẤT DỄ',
            subLabel: 'Thuộc lòng',
            color: const Color(0xFF4FC3F7),
            bgColor: const Color(0xFF0F2532),
            icon: Icons.bolt_rounded,
            onTap: () => onReview(4),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required String subLabel,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          padding: EdgeInsets.zero,
          side: BorderSide(color: color, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}