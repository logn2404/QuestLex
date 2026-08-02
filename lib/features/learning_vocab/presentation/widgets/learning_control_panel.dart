import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:questlex/features/navigation/domain/app_screen.dart';
import 'package:questlex/features/navigation/presentation/controllers/navigation_controller.dart';

class LearningControlPanel extends StatelessWidget {
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onToggleSelection;
  final VoidCallback onStartLearning;

  const LearningControlPanel({
    super.key,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onToggleSelection,
    required this.onStartLearning,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = selectedCount > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFD0BCFF).withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🎯 1. NÚT "HỌC NGAY" VỚI BADGE SỐ TỪ ĐÍNH Ở GÓC (NẰM TRÊN)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: hasSelection
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Nút chính
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: onStartLearning,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purpleAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 4,
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 22),
                              label: const Text(
                                'HỌC NGAY',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),

                          // 🏷️ Badge số từ đính ở góc trên bên phải
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amberAccent.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                '$selectedCount TỪ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // 🎯 2. NÚT CHỌN TỪ / THOÁT CHẾ ĐỘ CHỌN (NẰM DƯỚI)
            OutlinedButton.icon(
              onPressed: onToggleSelection,
              style: OutlinedButton.styleFrom(
                foregroundColor: isSelectionMode ? Colors.amber : Colors.white70,
                side: BorderSide(
                  color: isSelectionMode ? Colors.amber : Colors.white24,
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(
                isSelectionMode ? Icons.close_rounded : Icons.checklist_rounded,
                size: 18,
              ),
              label: Text(
                isSelectionMode ? 'THOÁT CHẾ ĐỘ CHỌN' : 'CHỌN TỪ ĐỂ HỌC',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, color: Colors.white12),
            ),

            // 🚀 3. LỐI TẮT NHANH (NAVIGATION SỐNG ĐỘNG RỰC RỠ)
            Text(
              'Lối tắt nhanh',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFFD0BCFF),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Nút chuyển sang Kho từ vựng đã thuộc
            _buildMiniMenuButton(
              context,
              icon: Icons.menu_book_rounded,
              iconColor: Colors.tealAccent, // Icon Xanh ngọc
              label: 'Kho từ vựng đã thuộc',
              onTap: () {
                context.read<NavigationController>().navigateTo(AppScreen.inventory);
              },
            ),
            const SizedBox(height: 6),

            // Nút chuyển sang Streak
            _buildMiniMenuButton(
              context,
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.orangeAccent, // Icon Cam lửa
              label: 'Chuỗi ngày học (Streak)',
              onTap: () {
                context.read<NavigationController>().navigateTo(AppScreen.streak);
              },
            ),
            const SizedBox(height: 6),

            // Nút chuyển về Trang chủ (Dashboard)
            _buildMiniMenuButton(
              context,
              icon: Icons.dashboard_rounded,
              iconColor: Colors.lightBlueAccent, // Icon Xanh dương
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
            // Ô vuông bọc Icon sống động
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