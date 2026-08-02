import 'dart:async';
import 'package:flutter/material.dart';

class MatchingTransitionOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const MatchingTransitionOverlay({super.key, required this.onComplete});

  @override
  State<MatchingTransitionOverlay> createState() =>
      _MatchingTransitionOverlayState();
}

class _MatchingTransitionOverlayState extends State<MatchingTransitionOverlay> {
  final List<String> _vocabPool = [
    'WARRIOR', 'SHIELD', 'QUEST', 'VICTORY', 'LEGEND', 'DRAGON',
    'KINGDOM', 'PAWN', 'MASTERY', 'SPELL', 'KNIGHT', 'PINNACLE',
    'LEXICON', 'STREAK', 'EXP', 'LEVEL_UP', 'CHALLENGE', 'RUNE',
    'SYNONYM', 'ANTONYM', 'DEFINITION', 'GRAMMAR', 'PHRASE', 'BATTLE'
  ];

  int _visibleChipsCount = 0;
  late Timer _chipTimer;

  @override
  void initState() {
    super.initState();

    _chipTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_visibleChipsCount < 200) {
        setState(() => _visibleChipsCount += 4);
      } else {
        _chipTimer.cancel();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _chipTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 🎯 ÉP PHỦ KÍN 100% TOÀN MÀN HÌNH TỪ ĐỈNH TỚI ĐÁY
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0A0E1A), // Nền tối che sạch sẽ bên dưới
              child: Transform.scale(
                scale: 1.2, // Phóng nhẹ để không bị hở viền ngoài
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: List.generate(_visibleChipsCount, (index) {
                      final word = _vocabPool[index % _vocabPool.length];
                      final isEven = index % 2 == 0;
                      return AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOutBack,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isEven
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.blueAccent.shade100, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.blueAccent, blurRadius: 8),
                            ],
                          ),
                          child: Text(
                            word,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}