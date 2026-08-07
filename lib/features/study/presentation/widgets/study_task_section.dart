import 'package:flutter/material.dart';

import 'package:questlex/features/study/presentation/widgets/study_mode_card.dart';
import 'package:questlex/features/study/presentation/widgets/transitions/flashcard_transition.dart';
import 'package:questlex/features/study/presentation/widgets/transitions/matching_transition.dart';
import 'package:questlex/features/study/presentation/widgets/transitions/word_fill_transition.dart';

class StudyTaskSection extends StatefulWidget {
  const StudyTaskSection({super.key});

  @override
  State<StudyTaskSection> createState() => _StudyTaskSectionState();
}

class _StudyTaskSectionState extends State<StudyTaskSection> {
  OverlayEntry? _overlayEntry;

  /// Kích hoạt Overlay tràn FULL 100% toàn bộ màn hình hệ thống
  void _showFullScreenTransition(
    Widget Function(VoidCallback onComplete) builder,
    VoidCallback onTargetNavigation,
  ) {
    _overlayEntry = OverlayEntry(
      builder: (context) => builder(() {
        _removeOverlay();
        onTargetNavigation();
      }),
    );

    final rootOverlay = Overlay.of(context, rootOverlay: true);
    rootOverlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 700;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 3 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          // 🎯 Đã tăng tỉ lệ Aspect Ratio lên (1.35 cho desktop) để card ngắn & gọn gàng hơn
          childAspectRatio: isDesktop ? 1.35 : 1.8,
          children: [
            // 1. FLASH CARD
            StudyModeCard(
              title: 'FLASH CARD',
              description: 'Lật thẻ tương tác xem từ vựng, âm thanh & nghĩa',
              icon: const Icon(
                Icons.style_rounded,
                color: Color(0xFFE53935),
                size: 32,
              ),
              themeColor: const Color(0xFFE53935),
              onDoubleClick: () => _showFullScreenTransition(
                (onComplete) =>
                    FlashcardTransitionOverlay(onComplete: onComplete),
                () {
                  // TODO: Navigator sang FlashcardPage
                },
              ),
            ),

            // 2. MATCHING CARD
            StudyModeCard(
              title: 'MATCHING CARD',
              description: 'Nối từ nhanh với Synonyms & Definition',
              icon: const Icon(
                Icons.extension_rounded,
                color: Color(0xFF3B82F6),
                size: 32,
              ),
              themeColor: const Color(0xFF3B82F6),
              onDoubleClick: () => _showFullScreenTransition(
                (onComplete) =>
                    MatchingTransitionOverlay(onComplete: onComplete),
                () {
                  // TODO: Navigator sang MatchingCardPage
                },
              ),
            ),

            // 3. TYPING WORD (Đã đổi tên & cập nhật title mới)
            StudyModeCard(
              title: 'TYPING WORD',
              description: 'Gõ lại chính xác từ vựng theo định nghĩa',
              icon: const Icon(
                Icons.keyboard_rounded,
                color: Color(0xFF10B981),
                size: 32,
              ),
              themeColor: const Color(0xFF10B981),
              onDoubleClick: () => _showFullScreenTransition(
                (onComplete) =>
                    WordFillTransitionOverlay(onComplete: onComplete),
                () {
                  // TODO: Navigator sang TypingWordPage
                },
              ),
            ),
          ],
        );
      },
    );
  }
}