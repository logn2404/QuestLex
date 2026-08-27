import 'package:flutter/material.dart';

class MatchingTileData {
  final String id;
  final String text;
  final String matchGroup;
  final bool isWord;
  bool isSelected;
  bool isMatched;

  MatchingTileData({
    required this.id,
    required this.text,
    required this.matchGroup,
    required this.isWord,
    this.isSelected = false,
    this.isMatched = false,
  });
}

class MatchingTileCard extends StatelessWidget {
  final MatchingTileData tile;
  final bool isFeverActive;
  final VoidCallback onTap;

  const MatchingTileCard({
    super.key,
    required this.tile,
    required this.isFeverActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tile.isMatched) {
      return const SizedBox.shrink();
    }

    final Color bgColor = isFeverActive ? const Color(0xFF060A0D) : const Color(0xFF101921);
    Color borderColor = tile.isWord
        ? const Color(0xFF00B0FF).withValues(alpha: 0.4)
        : const Color(0xFF18FFFF).withValues(alpha: 0.25);

    if (tile.isSelected) {
      borderColor = const Color(0xFF00E5FF);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: tile.isSelected ? const Color(0xFF003D46) : bgColor,
          borderRadius: BorderRadius.circular(8), // 🎯 Bo góc gọn hơn (8px)
          border: Border.all(
            color: borderColor,
            width: tile.isSelected ? 2.0 : 1.0,
          ),
          boxShadow: tile.isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 🎯 Thu nhỏ padding
        alignment: Alignment.center,
        child: Text(
          tile.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tile.isSelected ? const Color(0xFF00E5FF) : Colors.white,
            fontWeight: tile.isWord ? FontWeight.bold : FontWeight.w500,
            fontSize: tile.isWord ? 13 : 11, // 🎯 Điều chỉnh size chữ siêu gọn
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}