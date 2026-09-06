import 'package:flutter/material.dart';

class SynchronizeMeterBar extends StatelessWidget {
  final double syncValue;
  final bool isSyncActive;

  const SynchronizeMeterBar({
    super.key,
    required this.syncValue,
    required this.isSyncActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSyncActive ? const Color(0xFF00E5FF) : Colors.white12,
          width: isSyncActive ? 2 : 1,
        ),
        boxShadow: isSyncActive
            ? [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      padding: const EdgeInsets.all(3),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          FractionallySizedBox(
            heightFactor: syncValue.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFFFF1744),
                    Color(0xFFFF9100),
                    Color(0xFFFFEA00),
                    Color(0xFF00E676),
                    Color(0xFF00E5FF),
                  ],
                ),
              ),
            ),
          ),
          if (isSyncActive)
            const Positioned(
              top: 4,
              child: Icon(Icons.sync_rounded, color: Color(0xFF00E5FF), size: 16),
            ),
        ],
      ),
    );
  }
}