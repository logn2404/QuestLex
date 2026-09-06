import 'dart:math';
import 'package:flutter/material.dart';

class FlashcardFlipperCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isFlipped;
  final bool isFeverActive;
  final VoidCallback onTap;

  const FlashcardFlipperCard({
    super.key,
    required this.item,
    required this.isFlipped,
    required this.isFeverActive,
    required this.onTap,
  });

  @override
  State<FlashcardFlipperCard> createState() => _FlashcardFlipperCardState();
}

class _FlashcardFlipperCardState extends State<FlashcardFlipperCard> {
  late PageController _pageController;
  int _virtualPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didUpdateWidget(covariant FlashcardFlipperCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🎯 Khi từ vựng thay đổi (qua từ mới) -> kích hoạt animation Slide Left sang trang tiếp theo
    if (oldWidget.item['word'] != widget.item['word']) {
      _virtualPageIndex++;
      _pageController.animateToPage(
        _virtualPageIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(), // Khóa vuốt tay, chỉ trượt bằng code
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: widget.onTap,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: widget.isFlipped ? 180 : 0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              final isBack = val >= 90;
              final angle = val * pi / 180;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // 🎯 Perspective 3D
                  ..rotateY(angle),
                child: isBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _buildCardContent(isFront: false),
                      )
                    : _buildCardContent(isFront: true),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCardContent({required bool isFront}) {
    final englishDefinition = widget.item['definition'] ??
        widget.item['meaning'] ??
        'Chưa có định nghĩa';
    final vietnameseMeaning = _shortVietnameseMeaning;
    final example = widget.item['context_example'] ?? 'Chưa có câu ví dụ';

    // Hiệu ứng Withered khi vào Fever Mode
    final Color cardBgColor = widget.isFeverActive
        ? const Color(0xFF0D0E12)
        : const Color(0xFF1E1E24);

    final Color borderColor = widget.isFeverActive
        ? Colors.grey.shade800
        : (isFront ? Colors.redAccent.withValues(alpha: 0.4) : Colors.amberAccent.withValues(alpha: 0.4));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: widget.isFeverActive ? 1.0 : 1.5),
        boxShadow: widget.isFeverActive
            ? []
            : [
                BoxShadow(
                  color: isFront ? Colors.redAccent.withValues(alpha: 0.15) : Colors.amberAccent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isFeverActive
                  ? Colors.white.withValues(alpha: 0.05)
                  : (isFront ? Colors.redAccent.withValues(alpha: 0.15) : Colors.amberAccent.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(widget.item['pos'] ?? 'WORD').toString().toUpperCase()} • CEFR ${(widget.item['level'] ?? 'A1').toString().toUpperCase()}',
              style: TextStyle(
                color: widget.isFeverActive ? Colors.grey.shade500 : (isFront ? Colors.redAccent : Colors.amberAccent),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            isFront
                ? (widget.item['word'] ?? '').toString().toUpperCase()
                : vietnameseMeaning,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.isFeverActive ? Colors.grey.shade300 : Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          if (isFront) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, color: widget.isFeverActive ? Colors.grey.shade700 : Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text('Nhấp vào thẻ để lật xem nghĩa', style: TextStyle(color: widget.isFeverActive ? Colors.grey.shade700 : Colors.grey, fontSize: 13)),
              ],
            ),
          ] else ...[
            const Divider(color: Colors.white12, height: 32),
            const Text(
              'ĐỊNH NGHĨA ENGLISH',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              englishDefinition.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.isFeverActive ? Colors.grey.shade400 : Colors.amberAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '"$example"',
              textAlign: TextAlign.center,
              style: TextStyle(color: widget.isFeverActive ? Colors.grey.shade700 : Colors.grey.shade400, fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  String get _shortVietnameseMeaning {
    final rawMeaning = (widget.item['vietnamese_meaning'] ??
            widget.item['meaning_vi'] ??
            widget.item['viMeaning'] ??
            widget.item['meaning'] ??
            'Chưa có nghĩa tiếng Việt')
        .toString()
        .trim();
    if (rawMeaning.isEmpty) return 'Chưa có nghĩa tiếng Việt';

    final firstMeaning = rawMeaning
        .split(RegExp(r'[,;/|]'))
        .first
        .trim();
    final words = firstMeaning.split(RegExp(r'\s+'));
    return words.length <= 2 ? firstMeaning : words.take(2).join(' ');
  }
}