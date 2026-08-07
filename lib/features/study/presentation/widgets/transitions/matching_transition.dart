import 'dart:async';
import 'package:flutter/material.dart';

class MatchingTransitionOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const MatchingTransitionOverlay({super.key, required this.onComplete});

  @override
  State<MatchingTransitionOverlay> createState() =>
      _MatchingTransitionOverlayState();
}

class _MatchingTransitionOverlayState
    extends State<MatchingTransitionOverlay> {
  final List<String> _vocabPool = [
    'WARRIOR', 'SHIELD', 'QUEST', 'VICTORY', 'LEGEND', 'DRAGON',
    'KINGDOM', 'PAWN', 'MASTERY', 'SPELL', 'KNIGHT', 'PINNACLE',
    'LEXICON', 'STREAK', 'EXP', 'LEVEL_UP', 'CHALLENGE', 'RUNE',
    'SYNONYM', 'ANTONYM', 'DEFINITION', 'GRAMMAR', 'PHRASE', 'BATTLE'
  ];

  int _visibleChipsCount = 0;
  late Timer _chipTimer;

  // Set chứa danh sách index của các thẻ ĐÃ BIẾN MẤT
  final Set<int> _hiddenChipIndices = {};
  Timer? _disappearTimer;

  @override
  void initState() {
    super.initState();

    // 1. Pha 1: Bắn thẻ lấp kín màn hình cực nhanh
    _chipTimer = Timer.periodic(const Duration(milliseconds: 3), (timer) {
      if (_visibleChipsCount < 380) {
        setState(() => _visibleChipsCount += 12);
      } else {
        _chipTimer.cancel();
        _startRandomDisappear(); // Chuyển sang Pha 2: Biến mất ngẫu nhiên
      }
    });
  }

  /// 2. Pha 2: Xóa ngẫu nhiên các từ trên màn hình
  void _startRandomDisappear() {
    // Tạo danh sách index từ 0 -> _visibleChipsCount và xáo trộn ngẫu nhiên
    final List<int> allIndices = List.generate(_visibleChipsCount, (i) => i);
    allIndices.shuffle();

    int step = 0;
    _disappearTimer = Timer.periodic(const Duration(milliseconds: 12), (timer) {
      if (step < allIndices.length) {
        setState(() {
          // Mỗi nhịp biến mất ngẫu nhiên 12-15 thẻ ở các vị trí khác nhau
          final end = (step + 14 < allIndices.length) ? step + 14 : allIndices.length;
          for (int i = step; i < end; i++) {
            _hiddenChipIndices.add(allIndices[i]);
          }
          step = end;
        });
      } else {
        _disappearTimer?.cancel();
        // Sau khi biến mất sạch sẽ thì kết thúc transition
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _chipTimer.cancel();
    _disappearTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Nền tối xanh giữ nguyên phía sau
          Positioned.fill(
            child: Container(color: const Color(0xFF0A0E1A)),
          ),

          // Lưới mảnh ghép từ vựng
          Positioned(
            top: -40,
            bottom: -40,
            left: -40,
            right: -120,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.start,
                children: List.generate(_visibleChipsCount, (index) {
                  final word = _vocabPool[index % _vocabPool.length];
                  final isEven = index % 2 == 0;
                  final isHidden = _hiddenChipIndices.contains(index);

                  return AnimatedScale(
                    scale: isHidden ? 0.0 : 1.0, // 🎯 Thu nhỏ về 0 để biến mất ngẫu nhiên
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeInBack,
                    child: AnimatedOpacity(
                      opacity: isHidden ? 0.0 : 1.0, // 🎯 Mờ dần
                      duration: const Duration(milliseconds: 100),
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
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}