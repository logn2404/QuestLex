import 'package:flutter/material.dart';

class DamageIndicator {
  static void show(BuildContext context, {required String text, required Color color}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _DamageTextAnimation(
        text: text,
        color: color,
        onComplete: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _DamageTextAnimation extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onComplete;

  const _DamageTextAnimation({
    required this.text,
    required this.color,
    required this.onComplete,
  });

  @override
  State<_DamageTextAnimation> createState() => _DamageTextAnimationState();
}

class _DamageTextAnimationState extends State<_DamageTextAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translateY;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );

    _translateY = Tween<double>(begin: 0.0, end: -90.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.4, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: size.width / 2 - 80,
          top: size.height / 2 - 120 + _translateY.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: SizedBox(
                width: 160,
                child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    shadows: [
                      Shadow(blurRadius: 10, color: widget.color.withOpacity(0.8), offset: Offset.zero),
                      const Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}