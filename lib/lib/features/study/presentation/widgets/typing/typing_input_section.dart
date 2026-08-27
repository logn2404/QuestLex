import 'package:flutter/material.dart';

class TypingInputSection extends StatelessWidget {
  final String targetWord;
  final List<bool> revealedChars;
  final int hintCountLeft;
  final bool isAnswered;
  final TextEditingController textController;
  final FocusNode focusNode;
  final int remainingWords;
  final VoidCallback onHintPressed;
  final VoidCallback onSubmit;

  const TypingInputSection({
    super.key,
    required this.targetWord,
    required this.revealedChars,
    required this.hintCountLeft,
    required this.isAnswered,
    required this.textController,
    required this.focusNode,
    required this.remainingWords,
    required this.onHintPressed,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Nút HINT + Badge lượt đếm
        Stack(
          clipBehavior: Clip.none,
          children: [
            ElevatedButton(
              onPressed: (hintCountLeft > 0 && !isAnswered) ? onHintPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C38),
                disabledBackgroundColor: Colors.white10,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
              child: const Text(
                'HINT',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hintCountLeft > 0 ? Colors.amber : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$hintCountLeft',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 16),

        // 2. Ô nhập văn bản + Hiển thị gạch ký tự
        Expanded(
          child: Column(
            children: [
              Wrap(
                spacing: 6,
                children: List.generate(targetWord.length, (index) {
                  if (targetWord[index] == ' ') {
                    return const SizedBox(width: 12);
                  }
                  final isRevealed = revealedChars.length > index && revealedChars[index];
                  return Text(
                    isRevealed ? targetWord[index].toUpperCase() : '_',
                    style: TextStyle(
                      color: isRevealed ? Colors.amberAccent : Colors.white54,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                focusNode: focusNode,
                enabled: !isAnswered,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập từ vựng...',
                  hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 1),
                  filled: true,
                  fillColor: const Color(0xFF1A1A22),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // 3. Khung đếm từ vựng
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            '$remainingWords\nwords',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}