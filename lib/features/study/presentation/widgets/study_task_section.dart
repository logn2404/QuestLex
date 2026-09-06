import 'package:flutter/material.dart';

import '../pages/matching_card_page.dart';
import '../pages/word_typing_page.dart';
import 'flashcard/flashcard_session_view.dart';
import 'study_mode_card.dart';
import 'transitions/flashcard_transition.dart';
import 'transitions/matching_transition.dart';
import 'transitions/word_fill_transition.dart';

class StudyTaskSection extends StatefulWidget {
  final List<Map<String, dynamic>> words;
  final Function(String word, int quality) onReview;

  const StudyTaskSection({
    super.key,
    required this.words,
    required this.onReview,
  });

  @override
  State<StudyTaskSection> createState() => _StudyTaskSectionState();
}

class _StudyTaskSectionState extends State<StudyTaskSection> {
  OverlayEntry? _overlayEntry;

  /// Kích hoạt Overlay tràn màn hình bằng Overlay.of(context) gióng theo Flashcard
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

    // 🎯 Lấy Overlay chuẩn tương tự Flashcard, không dùng rootNavigator gây lỗi
    final overlayState = Overlay.of(context);
    overlayState.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleWordFillSelection(
    BuildContext context,
    List<Map<String, dynamic>> words,
  ) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => WordFillTransitionOverlay(
        onComplete: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, animation, secondaryAnimation) {
                return WordTypingPage(
                  words: words,
                  onReview: widget.onReview,
                );
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );

          Future.delayed(const Duration(milliseconds: 600), () {
            if (overlayEntry.mounted) {
              overlayEntry.remove();
            }
          });
        },
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(overlayEntry);
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
          childAspectRatio: isDesktop ? 1.35 : 1.8,
          children: [
            // 1. FLASH CARD
            StudyModeCard(
              title: 'FLASH CARD',
              description: 'Lật thẻ tương tác xem từ vựng, âm thanh & nghĩa',
              icon: const Icon(
                Icons.view_carousel_rounded,
                color: Color(0xFFE53935),
                size: 32,
              ),
              themeColor: const Color(0xFFE53935),
              onDoubleClick: () => _showFullScreenTransition(
                (onComplete) =>
                    FlashcardTransitionOverlay(onComplete: onComplete),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardSessionView(
                        words: widget.words,
                        onReview: widget.onReview,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. MATCHING CARD
            StudyModeCard(
              title: 'MATCHING CARD',
              description: 'Nối từ nhanh với Synonyms & Definition',
              icon: const Icon(
                Icons.extension_rounded,
                color: Color(0xFF00E5FF),
                size: 32,
              ),
              themeColor: const Color(0xFF00E5FF),
              onDoubleClick: () => _showFullScreenTransition(
                (onComplete) =>
                    MatchingTransitionOverlay(onComplete: onComplete),
                () {
                  // 🎯 Đã cập nhật điều hướng thật sang MatchingCardPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchingCardPage(
                        words: widget.words,
                        onReview: widget.onReview,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. TYPING WORD
            StudyModeCard(
              title: 'TYPING WORD',
              description: 'Gõ lại chính xác từ vựng theo định nghĩa',
              icon: const Icon(
                Icons.keyboard_rounded,
                color: Color(0xFF10B981),
                size: 32,
              ),
              themeColor: const Color(0xFF10B981),
              onDoubleClick: () =>
                  _handleWordFillSelection(context, widget.words),
            ),
          ],
        );
      },
    );
  }
}