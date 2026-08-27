import 'package:flutter/material.dart';
import '../widgets/matching/matching_card_session_view.dart';

class MatchingCardPage extends StatelessWidget {
  final List<Map<String, dynamic>> words;
  final Function(String word, int quality) onReview;

  const MatchingCardPage({
    super.key,
    required this.words,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return MatchingCardSessionView(
      words: words,
      onReview: onReview,
    );
  }
}