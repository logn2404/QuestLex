import 'package:flutter/material.dart';

class TypingActionButtons extends StatelessWidget {
  final bool isAnswered;
  final VoidCallback onGiveUp;
  final VoidCallback onSubmit;

  const TypingActionButtons({
    super.key,
    required this.isAnswered,
    required this.onGiveUp,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: !isAnswered ? onGiveUp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'GIVE UP!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              isAnswered ? 'TIẾP TỤC' : 'SUBMIT',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}