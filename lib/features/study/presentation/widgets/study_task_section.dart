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
    String screenName,
  ) {
    _overlayEntry = OverlayEntry(
      builder: (context) => builder(() {
        _removeOverlay();
        // TODO: Chuyển hướng màn hình học tương ứng sau khi chạy xong transition
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã chuyển sang $screenName!')),
          );
        }
      }),
    );

    // 🎯 Lấy rootOverlay: true để Overlay đè lên toàn bộ Scaffold, TopBar & Banner
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
          childAspectRatio: isDesktop ? 0.95 : 1.4,
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
                'FLASH CARD',
              ),
            ),

            // 2. MATCHING CARD (XÂY MẢNH GHÉP TỪ VỰNG KÍN MÀN HÌNH)
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
                'MATCHING CARD',
              ),
            ),

            // 3. WORD FILL
            StudyModeCard(
              title: 'WORD FILL',
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
                'WORD FILL',
              ),
            ),
          ],
        );
      },
    );
  }
}