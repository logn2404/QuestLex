import 'package:flutter/material.dart';
import '../inventory_controller.dart';

class InventorySearchBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final SortOption currentSort;
  final ValueChanged<SortOption> onSortChanged;

  const InventorySearchBar({
    super.key,
    required this.onSearchChanged,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Search Input Bar
        Expanded(
          child: TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm từ vựng đã thuộc...',
              hintStyle: TextStyle(color: theme.hintColor),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.greenAccent),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.greenAccent, width: 1.5),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHigh,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Popup Menu chọn kiểu Sort (ĐÃ CHỈNH TÔNG XANH LÁ - TRẮNG)
        PopupMenuButton<SortOption>(
          initialValue: currentSort,
          onSelected: onSortChanged,
          tooltip: 'Sắp xếp danh sách',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15), // Nền xanh lá nhạt
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.4)), // Viền xanh
            ),
            child: const Icon(Icons.sort_rounded, color: Colors.greenAccent, size: 20), // Icon xanh tươi
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: SortOption.alphabetAsc,
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha_rounded, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Tên (A -> Z)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: SortOption.alphabetDesc,
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha_rounded, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Tên (Z -> A)'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: SortOption.difficultyAsc,
              child: Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Độ khó tăng dần (A1 -> C2)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: SortOption.difficultyDesc,
              child: Row(
                children: [
                  Icon(Icons.arrow_downward_rounded, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Độ khó giảm dần (C2 -> A1)'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}