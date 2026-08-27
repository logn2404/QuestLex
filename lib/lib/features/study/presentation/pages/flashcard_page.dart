import 'package:flutter/material.dart';
import '../widgets/flashcard/flashcard_session_view.dart';

class FlashcardPage extends StatelessWidget {
  final List<Map<String, dynamic>> words;
  final Function(String word, int quality) onReview;

  const FlashcardPage({
    super.key,
    required this.words,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return FlashcardSessionView(
      words: words,
      onReview: onReview,
    );
  }
}