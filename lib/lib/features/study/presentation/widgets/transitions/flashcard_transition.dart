import 'dart:math';
import 'package:flutter/material.dart';

class FlashcardTransitionOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const FlashcardTransitionOverlay({super.key, required this.onComplete});

  @override
  State<FlashcardTransitionOverlay> createState() => _FlashcardTransitionOverlayState();
}

class _FlashcardTransitionOverlayState extends State<FlashcardTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _flipAnimation = Tween<double>(begin: 0, end: pi * 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 25.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeInExpo),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black45, // Nền mờ phía sau
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_flipAnimation.value),
                child: Container(
                  width: 220,
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withValues(alpha: 0.6),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.style_rounded, size: 80, color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}