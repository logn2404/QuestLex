import 'package:flutter/material.dart';

class FeverMeterBar extends StatelessWidget {
  final double feverValue; // Value từ 0.0 -> 1.0
  final bool isFeverActive;

  const FeverMeterBar({
    super.key,
    required this.feverValue,
    required this.isFeverActive,
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
          color: isFeverActive ? Colors.cyanAccent : Colors.white12,
          width: isFeverActive ? 2 : 1,
        ),
        boxShadow: isFeverActive
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.8),
                  blurRadius: 16,
                  spreadRadius: 3,
                )
              ]
            : [],
      ),
      padding: const EdgeInsets.all(3),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Thanh màu Gradient trượt từ Đỏ -> Xanh
          FractionallySizedBox(
            heightFactor: feverValue.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFFFF1744), // Đỏ
                    Color(0xFFFF9100), // Cam
                    Color(0xFFFFEA00), // Vàng
                    Color(0xFF00E676), // Xanh lá
                    Color(0xFF00E5FF), // Xanh ngọc
                  ],
                ),
              ),
            ),
          ),
          if (isFeverActive)
            const Positioned(
              top: 4,
              child: Icon(Icons.bolt_rounded, color: Colors.cyanAccent, size: 16),
            ),
        ],
      ),
    );
  }
}