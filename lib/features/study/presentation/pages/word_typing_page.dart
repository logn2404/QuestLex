import 'package:flutter/material.dart';
import '../widgets/typing/word_typing_session_view.dart';

class WordTypingPage extends StatelessWidget {
  final List<Map<String, dynamic>> words;
  final Function(String word, int quality) onReview;

  const WordTypingPage({
    super.key,
    required this.words,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F12),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text(
            'Không có từ vựng nào trong hàng chờ!',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return WordTypingSessionView(
      words: words,
      onReview: onReview,
      onFinished: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E24),
            title: const Text('Hoàn thành!', style: TextStyle(color: Colors.white)),
            content: const Text('Bạn đã hoàn thành lượt luyện tập Typing Word!',
                style: TextStyle(color: Colors.white70)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Quay lại'),
              ),
            ],
          ),
        );
      },
    );
  }
}