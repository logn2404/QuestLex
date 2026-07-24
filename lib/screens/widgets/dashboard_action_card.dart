import 'package:flutter/material.dart';

class DashboardActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget subContent;
  final VoidCallback? onTap;

  const DashboardActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.subContent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
        highlightColor: Colors.deepPurpleAccent.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.deepPurpleAccent),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              subContent,
            ],
          ),
        ),
      ),
    );
  }
}