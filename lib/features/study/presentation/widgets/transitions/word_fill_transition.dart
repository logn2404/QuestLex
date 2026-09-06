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

class _WordFillTransitionOverlayState extends State<WordFillTransitionOverlay>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _splitController;
  late Animation<double> _splitAnimation;

  @override
  void initState() {
    super.initState();

    _splitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _splitAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _splitController, curve: Curves.easeInOutCubic),
    );

    // Tạo 60 dải chữ (15 dải cuối sẽ đọng lại ở 2 biên)
    for (int i = 0; i < 60; i++) {
      final StringBuffer sb = StringBuffer();
      for (int j = 0; j < 10; j++) {
        sb.write('${_vocabWords[_random.nextInt(_vocabWords.length)]}  •  ');
      }

      final isSticky = i >= 45;
      _ribbonItems.add(
        _RibbonItem(
          text: sb.toString(),
          isHorizontal: i % 2 == 0,
          topRatio: _random.nextDouble(),
          leftRatio: _random.nextDouble(),
          isForward: _random.nextBool(),
          fontSize: _random.nextDouble() * 8 + 15,
          textColor: _random.nextBool()
              ? const Color(0xFF10B981)
              : const Color(0xFF34D399),
          durationMs: isSticky ? 500 : _random.nextInt(200) + 250,
          isStickyToSide: isSticky,
        ),
      );
    }

    // Kích hoạt bão chữ dồn dập
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_visibleCount < _ribbonItems.length) {
        setState(() => _visibleCount++);
      } else {
        _timer.cancel();

        // 🎯 Kích hoạt Split Curtain: Bắn callback dựng UI bên dưới NGAY LẬP TỨC khi rèm bắt đầu tách
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) {
            widget.onComplete(); // Bật WordTypingPage ngay bên dưới rèm trượt
            _splitController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _splitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final halfWidth = screenSize.width / 2;

    return AnimatedBuilder(
      animation: _splitController,
      builder: (context, child) {
        final slideOffset = _splitAnimation.value * halfWidth;

        return Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 👈 NỬA TRÁI (Trượt từ giữa ra biên trái)
              Positioned(
                top: 0,
                bottom: 0,
                left: -slideOffset,
                width: halfWidth,
                child: ClipRect(
                  child: Stack(
                    children: [
                      Container(color: const Color(0xFF04120C)),
                      ..._buildHalfScreenRibbons(screenSize, isLeftHalf: true),
                    ],
                  ),
                ),
              ),

              // 👉 NỬA PHẢI (Trượt từ giữa ra biên phải)
              Positioned(
                top: 0,
                bottom: 0,
                right: -slideOffset,
                width: halfWidth,
                child: ClipRect(
                  child: Stack(
                    children: [
                      Container(color: const Color(0xFF04120C)),
                      ..._buildHalfScreenRibbons(screenSize, isLeftHalf: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildHalfScreenRibbons(Size screenSize, {required bool isLeftHalf}) {
    final List<Widget> widgets = [];
    for (int i = 0; i < _visibleCount; i++) {
      final item = _ribbonItems[i];
      widgets.add(_buildAnimatedTextLine(item, screenSize, isLeftHalf: isLeftHalf));
    }
    return widgets;
  }

  Widget _buildAnimatedTextLine(_RibbonItem item, Size screenSize, {required bool isLeftHalf}) {
    if (item.isHorizontal) {
      final topPos = item.topRatio * (screenSize.height - 30);
      double startX = item.isForward ? -screenSize.width : screenSize.width;
      double endX = item.isForward ? screenSize.width : -screenSize.width;

      if (item.isStickyToSide) {
        endX = isLeftHalf ? -screenSize.width * 0.25 : screenSize.width * 0.25;
      }

      final xOffsetCorrection = isLeftHalf ? 0.0 : -screenSize.width / 2;

      return Positioned(
        top: topPos,
        left: xOffsetCorrection,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: startX, end: endX),
          duration: Duration(milliseconds: item.durationMs),
          curve: Curves.easeOutCubic,
          builder: (context, xOffset, child) {
            return Transform.translate(
              offset: Offset(xOffset, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                color: Colors.black.withValues(alpha: 0.25),
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
                    shadows: [
                      Shadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      final leftPos = item.leftRatio * (screenSize.width - 30);
      final double startY = item.isForward ? -screenSize.height : screenSize.height;
      final double endY = item.isForward ? screenSize.height : -screenSize.height;
      final xOffsetCorrection = isLeftHalf ? 0.0 : -screenSize.width / 2;

      return Positioned(
        left: leftPos + xOffsetCorrection,
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
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  color: Colors.black.withValues(alpha: 0.25),
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
                      shadows: [
                        Shadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
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
  final bool isStickyToSide;

  _RibbonItem({
    required this.text,
    required this.isHorizontal,
    required this.topRatio,
    required this.leftRatio,
    required this.isForward,
    required this.fontSize,
    required this.textColor,
    required this.durationMs,
    this.isStickyToSide = false,
  });
}