import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class WordFillTransitionOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const WordFillTransitionOverlay({super.key, required this.onComplete});

  @override
  State<WordFillTransitionOverlay> createState() =>
      _WordFillTransitionOverlayState();
}

class _WordFillTransitionOverlayState
    extends State<WordFillTransitionOverlay> {
  final Random _random = Random();

  final List<String> _vocabWords = [
    'QUESTLEX', 'MASTERY', 'DICTIONARY', 'SYNONYM', 'PREPOSITION',
    'VOCABULARY', 'FLASHCARD', 'MATCHING', 'CHALLENGE', 'STREAK',
    'VICTORY', 'GAMIFICATION', 'SPELL', 'LEVEL_UP', 'EXP_BUFF', 'WORD_FILL',
    'PRONUNCIATION', 'DEFINITION', 'ANTONYM', 'GRAMMAR', 'PHRASAL_VERB'
  ];

  final List<_RibbonItem> _ribbonItems = [];
  int _visibleCount = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // Sinh ra 50 dòng chữ ngẫu nhiên chuẩn bị sẵn
    for (int i = 0; i < 50; i++) {
      final StringBuffer sb = StringBuffer();
      for (int j = 0; j < 10; j++) {
        sb.write('${_vocabWords[_random.nextInt(_vocabWords.length)]}  •  ');
      }

      _ribbonItems.add(
        _RibbonItem(
          text: sb.toString(),
          isHorizontal: i % 2 == 0, // Đan xen 1 dòng ngang, 1 dòng dọc
          topRatio: _random.nextDouble(),    // Tọa độ ngẫu nhiên từ 0% -> 100% màn hình
          leftRatio: _random.nextDouble(),   // Tọa độ ngẫu nhiên từ 0% -> 100% màn hình
          isForward: _random.nextBool(),
          fontSize: _random.nextDouble() * 6 + 14,
          textColor: _random.nextBool()
              ? const Color(0xFF10B981) // Matrix Green
              : const Color(0xFF34D399), // Neon Emerald
          durationMs: _random.nextInt(300) + 400, // Tốc độ trôi vụt qua
        ),
      );
    }

    // Timer cho các dòng chữ lao ra dồn dập rải rác khắp màn hình
    _timer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (_visibleCount < _ribbonItems.length) {
        setState(() => _visibleCount++);
      } else {
        _timer.cancel();
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent, // 🎯 BỎ NỀN XANH - Giữ nền trong suốt 100%
      child: Stack(
        fit: StackFit.expand,
        children: List.generate(_visibleCount, (index) {
          final item = _ribbonItems[index];
          return _buildAnimatedTextLine(item, screenSize);
        }),
      ),
    );
  }

  Widget _buildAnimatedTextLine(_RibbonItem item, Size screenSize) {
    if (item.isHorizontal) {
      // ↔ HÀNG CHỮ CHẠY NGANG (Tọa độ Y random từ 0 -> H)
      final topPos = item.topRatio * (screenSize.height - 30);
      final double startX = item.isForward ? -screenSize.width : screenSize.width;
      final double endX = item.isForward ? screenSize.width : -screenSize.width;

      return Positioned(
        top: topPos,
        left: 0,
        right: 0,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: startX, end: endX),
          duration: Duration(milliseconds: item.durationMs),
          curve: Curves.easeOutCubic,
          builder: (context, xOffset, child) {
            return Transform.translate(
              offset: Offset(xOffset, 0),
              child: Text(
                item.text,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: item.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: item.fontSize,
                  letterSpacing: 2,
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 4),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else {
      // ↕ HÀNG CHỮ CHẠY DỌC (Tọa độ X random từ 0 -> W)
      final leftPos = item.leftRatio * (screenSize.width - 30);
      final double startY = item.isForward ? -screenSize.height : screenSize.height;
      final double endY = item.isForward ? screenSize.height : -screenSize.height;

      return Positioned(
        left: leftPos,
        top: 0,
        bottom: 0,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: startY, end: endY),
          duration: Duration(milliseconds: item.durationMs),
          curve: Curves.easeOutCubic,
          builder: (context, yOffset, child) {
            return Transform.translate(
              offset: Offset(0, yOffset),
              child: RotatedBox(
                quarterTurns: item.isForward ? 1 : 3,
                child: Text(
                  item.text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: item.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: item.fontSize,
                    letterSpacing: 2,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }
}

class _RibbonItem {
  final String text;
  final bool isHorizontal;
  final double topRatio;
  final double leftRatio;
  final bool isForward;
  final double fontSize;
  final Color textColor;
  final int durationMs;

  _RibbonItem({
    required this.text,
    required this.isHorizontal,
    required this.topRatio,
    required this.leftRatio,
    required this.isForward,
    required this.fontSize,
    required this.textColor,
    required this.durationMs,
  });
}