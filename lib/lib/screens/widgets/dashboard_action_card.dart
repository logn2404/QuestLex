import 'package:flutter/material.dart';

class DashboardActionCard extends StatelessWidget {
  final String title;
  final IconData icon; // 🛡️ Giữ icon bắt buộc để tương thích code cũ
  final Widget? customIcon; // ⚔️ CustomIcon ghi đè nếu được truyền vào
  final VoidCallback onTap;
  final Widget subContent;

  const DashboardActionCard({
    super.key,
    required this.title,
    required this.icon,
    this.customIcon,
    required this.onTap,
    required this.subContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎯 Nếu có customIcon thì render customIcon đè lên, ngược lại dùng Icon mặc định
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: customIcon != null ? 0.0 : 1.0,
                    child: Icon(
                      icon,
                      size: 32,
                      color: const Color(0xFFD0BCFF),
                    ),
                  ),
                  ?customIcon,
                ],
              ),

              const SizedBox(height: 8),

              // Title Card
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 6),

              // SubContent
              subContent,
            ],
          ),
        ),
      ),
    );
  }
}