import 'package:flutter/material.dart';

class StudyModeCard extends StatefulWidget {
  final String title;
  final String description;
  final Widget icon;
  final Color themeColor;
  final VoidCallback onDoubleClick;

  const StudyModeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.themeColor,
    required this.onDoubleClick,
  });

  @override
  State<StudyModeCard> createState() => _StudyModeCardState();
}

class _StudyModeCardState extends State<StudyModeCard> {
  bool isHovered = false;
  DateTime? _lastTapTime;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      // 🎯 Phát hiện Double Click
      widget.onDoubleClick();
    }
    _lastTapTime = now;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedScale(
          scale: isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isHovered ? widget.themeColor : widget.themeColor.withValues(alpha: 0.3),
                width: isHovered ? 2.0 : 1.0,
              ),
              boxShadow: [
                if (isHovered)
                  BoxShadow(
                    color: widget.themeColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: widget.icon,
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Hint
                Text(
                  'Double click để chọn',
                  style: TextStyle(
                    fontSize: 10,
                    color: isHovered ? widget.themeColor : Colors.white24,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}