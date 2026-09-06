import 'package:flutter/material.dart';

class TypingHeaderProgress extends StatelessWidget {
  final int currentIndex;
  final int totalWords;

  const TypingHeaderProgress({
    super.key,
    required this.currentIndex,
    required this.totalWords,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: totalWords > 0 ? (currentIndex + 1) / totalWords : 0,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${currentIndex + 1}/$totalWords',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}