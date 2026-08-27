import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:questlex/features/navigation/domain/app_screen.dart';
import 'package:questlex/features/navigation/presentation/controllers/navigation_controller.dart';

class InventoryControlPanel extends StatelessWidget {
  const InventoryControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🎨 Định nghĩa hằng số màu Emerald chuẩn xịn
    const emeraldColor = Color(0xFF10B981);
    const emeraldAccentColor = Color(0xFF34D399);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // ✅ ĐÃ FIX: Thay Colors.emerald bằng emeraldColor
        side: BorderSide(color: emeraldColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TIÊU ĐỀ SECTION
            Text(
              'Lối tắt nhanh',
              style: theme.textTheme.labelSmall?.copyWith(
                // ✅ ĐÃ FIX: Thay Colors.emeraldAccent bằng emeraldAccentColor
                color: emeraldAccentColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // 1. Nút chuyển từ Inventory -> Learning Page
            _buildMiniMenuButton(
              context,
              icon: Icons.school_outlined,
              iconColor: Colors.purpleAccent,
              label: 'Từ vựng đang học',
              onTap: () {
                context.read<NavigationController>().navigateTo(AppScreen.learning);
              },
            ),
            const SizedBox(height: 6),

            // 2. Nút chuyển sang Streak
            _buildMiniMenuButton(
              context,
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.orangeAccent,
              label: 'Chuỗi ngày học (Streak)',
              onTap: () {
                context.read<NavigationController>().navigateTo(AppScreen.streak);
              },
            ),
            const SizedBox(height: 6),

            // 3. Nút quay về Trang chủ (Dashboard)
            _buildMiniMenuButton(
              context,
              icon: Icons.dashboard_rounded,
              iconColor: Colors.lightBlueAccent,
              label: 'Trang chủ (Dashboard)',
              onTap: () {
                context.read<NavigationController>().navigateTo(AppScreen.home);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMenuButton(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      hoverColor: iconColor.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}