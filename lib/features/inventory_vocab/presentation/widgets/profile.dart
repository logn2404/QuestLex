import 'package:flutter/material.dart';
import '../../../learning_vocab/domain/models/vocab_stats.dart';
import 'cerf_mas.dart';
import 'cerf_word_count.dart';

class Profile extends StatelessWidget {
  final VocabStats? stats;

  const Profile({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              CerfMas(
                overallScore: stats?.overallScore ?? 0,
                starRating: stats?.starRating ?? 0,
                expPercentage: stats?.expPercentage ?? 0.65,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              CerfWordCount(
                levelCounts: stats?.levelCounts ?? {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}