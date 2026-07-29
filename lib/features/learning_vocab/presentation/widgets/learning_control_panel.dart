import 'package:flutter/material.dart';
import 'package:questlex/features/inventory_vocab/presentation/inventory_page.dart';

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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. NÚT CHÍNH: CHỌN TỪ VỰNG / HỌC NGAY
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!isSelectionMode) {
                        onToggleSelection();
                      } else if (selectedCount > 0) {
                        onStartLearning();
                      } else {
                        onToggleSelection();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelectionMode && selectedCount > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHigh,
                      foregroundColor: isSelectionMode && selectedCount > 0
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      isSelectionMode && selectedCount > 0
                          ? Icons.play_arrow_rounded
                          : Icons.checklist_rounded,
                    ),
                    label: Text(
                      isSelectionMode && selectedCount > 0
                          ? 'HỌC NGAY'
                          : (isSelectionMode ? 'HỦY CHỌN' : 'CHỌN TỪ VỰNG'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                if (isSelectionMode && selectedCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        '$selectedCount từ',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // 2. DANH SÁCH NÚT MINI LIÊN KẾT
            Text(
              'Lối tắt nhanh',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 8),

            _buildMiniMenuButton(
              context,
              icon: Icons.inventory_2_outlined,
              label: 'Kho từ vựng đã thuộc',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InventoryPage(),
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
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}