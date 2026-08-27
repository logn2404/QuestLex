import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:questlex/features/navigation/domain/app_screen.dart';
import 'package:questlex/features/navigation/presentation/controllers/navigation_controller.dart';

class FastSwitchCard extends StatelessWidget {
  const FastSwitchCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = context.read<NavigationController>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Tông nền Card tối đồng bộ
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🎯 TIÊU ĐỀ SECTION: LỐI TẮT NHANH
          Text(
            'Lối tắt nhanh',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.orangeAccent.withValues(alpha: 0.8), // Tông cam hợp theme Streak
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // 1. DÒNG LỐI TẮT: TỪ VỰNG ĐANG HỌC
          _buildShortcutTile(
            context: context,
            icon: Icons.edit_note_rounded,
            iconColor: Colors.purpleAccent,
            title: 'Từ vựng đang học',
            onTap: () => nav.navigateTo(AppScreen.learning),
          ),

          const Divider(height: 16, color: Colors.white10),

          // 2. DÒNG LỐI TẮT: KHO TỪ VỰNG ĐÃ THUỘC
          _buildShortcutTile(
            context: context,
            icon: Icons.menu_book_rounded,
            iconColor: Colors.tealAccent,
            title: 'Kho từ vựng đã thuộc',
            onTap: () => nav.navigateTo(AppScreen.inventory),
          ),

          const Divider(height: 16, color: Colors.white10),

          // 3. DÒNG LỐI TẮT: TRANG CHỦ (DASHBOARD)
          _buildShortcutTile(
            context: context,
            icon: Icons.dashboard_rounded,
            iconColor: Colors.orangeAccent,
            title: 'Trang chủ (Dashboard)',
            onTap: () => nav.navigateTo(AppScreen.home),
          ),
        ],
      ),
    );
  }

  // 🎯 TÁI TẠO ITEM TILE ĐỒNG BỘ VỚI INVENTORY/LEARNING CONTROL PANEL
  Widget _buildShortcutTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          child: Row(
            children: [
              // Khung vuông bọc Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),

              // Tên lối tắt
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Mũi tên chuyển trang
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}