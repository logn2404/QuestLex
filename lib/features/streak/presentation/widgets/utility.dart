import 'package:flutter/material.dart';
import '../../data/streak_repository.dart';

class Utility extends StatelessWidget {
  final StreakData data;

  const Utility({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // 1. Ô STREAK FREEZE BĂNG
          Expanded(
            child: _buildItemTile(
              context: context,
              icon: Icons.ac_unit_rounded,
              iconColor: Colors.cyanAccent,
              title: '${data.streakFreezeCount} Băng',
              actionLabel: 'Dùng Băng',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã kích hoạt Băng bảo vệ Streak!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),

          Container(width: 1, height: 28, color: Colors.white12),

          // 2. Ô RƯƠNG PHẦN THƯỞNG
          Expanded(
            child: _buildItemTile(
              context: context,
              icon: Icons.card_giftcard_rounded,
              iconColor: Colors.amberAccent,
              title: '${data.availableChests} Rương',
              actionLabel: 'Mở Rương',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mở rương thành công! Nhận 50 EXP!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.white.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    actionLabel,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}