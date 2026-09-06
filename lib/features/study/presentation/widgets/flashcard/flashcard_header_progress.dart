import 'package:flutter/material.dart';

class FlashcardHeaderProgress extends StatelessWidget {
  final int currentIndex;
  final int totalWords;
  final VoidCallback onBackPressed;

  const FlashcardHeaderProgress({
    super.key,
    required this.currentIndex,
    required this.totalWords,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalWords > 0 ? (currentIndex + 1) / totalWords : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
              onPressed: onBackPressed,
            ),
            Text(
              'FLASHCARD HỌC TIẾNG ANH',
              style: TextStyle(
                color: Colors.redAccent.shade100,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 48), // Spacer cân đối với nút back
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${currentIndex + 1}/$totalWords words',
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}