import 'package:flutter/material.dart';
import 'package:questlex/features/learning_vocab/presentation/learning_page.dart';

class InventoryControlPanel extends StatelessWidget {
  const InventoryControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.withValues(alpha: 0.2)), // Viền xanh lá nhẹ cho Card
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DANH SÁCH NÚT MINI LIÊN KẾT (XẾP DỌC)
            Text(
              'Lối tắt nhanh',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.greenAccent.withValues(alpha: 0.8), // Tiêu đề xanh lá mạ
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Nút chuyển ngược lại từ Inventory -> Learning Page
            _buildMiniMenuButton(
              context,
              icon: Icons.school_outlined,
              label: 'Từ vựng đang học',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LearningPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),

            _buildMiniMenuButton(
              context,
              icon: Icons.local_fire_department_rounded,
              label: 'Chuỗi ngày học (Streak)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng Chuỗi ngày học (Streak) đang phát triển!'),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),

            _buildMiniMenuButton(
              context,
              icon: Icons.more_horiz_rounded,
              label: 'N/A',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: Colors.green.withValues(alpha: 0.1), // Hiệu ứng rê chuột xanh lá
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: [
            // Icon Xanh lá sáng
            Icon(icon, size: 18, color: Colors.greenAccent),
            const SizedBox(width: 10),
            
            // Text Trắng nổi bật
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white, // Chữ trắng
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Mũi tên xanh nhạt
            Icon(Icons.chevron_right_rounded, size: 16, color: Colors.green.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}