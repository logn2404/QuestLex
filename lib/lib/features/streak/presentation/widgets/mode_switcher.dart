import 'package:flutter/material.dart';
import '../streak_controller.dart';

class ModeSwitcher extends StatelessWidget {
  final StreakController controller;

  const ModeSwitcher({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabButton(
            label: 'Growth Rate',
            icon: Icons.show_chart_rounded,
            isSelected: controller.currentMode == StreakViewMode.growthChart,
            onTap: () => controller.setViewMode(StreakViewMode.growthChart),
          ),
          _buildTabButton(
            label: 'Top Vocab',
            icon: Icons.table_chart_rounded,
            isSelected: controller.currentMode == StreakViewMode.topVocabTable,
            onTap: () => controller.setViewMode(StreakViewMode.topVocabTable),
          ),
          _buildTabButton(
            label: 'Activity Map',
            icon: Icons.grid_on_rounded,
            isSelected: controller.currentMode == StreakViewMode.activityHeatmap,
            onTap: () => controller.setViewMode(StreakViewMode.activityHeatmap),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orangeAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.black : Colors.white70),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}