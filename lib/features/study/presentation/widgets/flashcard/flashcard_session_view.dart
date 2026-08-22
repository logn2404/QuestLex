import 'dart:async';
import 'package:flutter/material.dart';
import 'damage_indicator.dart';
import 'fever_meter_bar.dart';
import 'flashcard_action_buttons.dart';
import 'flashcard_flipper_card.dart';
import 'flashcard_header_progress.dart';

class FlashcardSessionView extends StatefulWidget {
  final List<Map<String, dynamic>> words;
  final Function(String word, int quality) onReview;

  const FlashcardSessionView({
    super.key,
    required this.words,
    required this.onReview,
  });

  @override
  State<FlashcardSessionView> createState() => _FlashcardSessionViewState();
}

class _FlashcardSessionViewState extends State<FlashcardSessionView> {
  int _currentIndex = 0;
  bool _isFlipped = false;

  // FEVER METER STATE
  double _feverValue = 0.0;
  bool _isFeverActive = false;
  Timer? _feverDrainTimer;

  // DAMAGE FLASH STATE
  bool _isDamageFlashActive = false;

  // 🎯 DOUBLE-CLICK / RAPID TAP PROTECTOR
  bool _isProcessingReview = false;

  void _triggerDamageFlash() {
    setState(() {
      _isDamageFlashActive = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isDamageFlashActive = false;
        });
      }
    });
  }

  void _activateFeverMode() {
    setState(() {
      _isFeverActive = true;
      _feverValue = 1.0;
    });

    final double totalSeconds = (widget.words.length / 2).clamp(4.0, 30.0);
    const int tickMs = 50;
    final double decrementPerTick = 1.0 / ((totalSeconds * 1000) / tickMs);

    _feverDrainTimer?.cancel();
    _feverDrainTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (!mounted) return;

      setState(() {
        _feverValue -= decrementPerTick;
        if (_feverValue <= 0.0) {
          _feverValue = 0.0;
          _isFeverActive = false;
          timer.cancel();
        }
      });
    });
  }

  void _handleReview(int quality) {
    // 🛡️ CHỐNG CLICK DỒN / DOUBLE CLICK (COOLDOWN 150ms)
    if (_isProcessingReview) return;
    _isProcessingReview = true;

    if (_currentIndex < widget.words.length) {
      final currentWord = widget.words[_currentIndex]['word'] ?? '';
      widget.onReview(currentWord, quality);

      int baseExp = 0;
      double feverDelta = 0.0;

      switch (quality) {
        case 1:
          baseExp = -10;
          feverDelta = -0.25;
          _triggerDamageFlash();
          break;
        case 2:
          baseExp = 5;
          feverDelta = 0.08;
          break;
        case 3:
          baseExp = 15;
          feverDelta = 0.20;
          break;
        case 4:
          baseExp = 25;
          feverDelta = 0.35;
          break;
      }

      int finalExp = baseExp;
      if (_isFeverActive && baseExp > 0) {
        finalExp = (baseExp * 1.25).round();
      }

      Color tickColor;
      if (finalExp < 0) {
        tickColor = const Color(0xFFFF5252);
      } else if (finalExp < 10) {
        tickColor = const Color(0xFFFFB74D);
      } else if (finalExp < 20) {
        tickColor = const Color(0xFF66BB6A);
      } else {
        tickColor = const Color(0xFF00E5FF);
      }

      final String tickText = finalExp >= 0 ? '+$finalExp EXP' : '$finalExp EXP';

      DamageIndicator.show(
        context,
        text: _isFeverActive && finalExp > 0 ? '$tickText (BUFF!)' : tickText,
        color: tickColor,
      );

      if (!_isFeverActive) {
        setState(() {
          _feverValue = (_feverValue + feverDelta).clamp(0.0, 1.0);
          if (_feverValue >= 1.0) {
            _activateFeverMode();
          }
        });
      }
    }

    setState(() {
      _isFlipped = false;
      if (_currentIndex < widget.words.length - 1) {
        _currentIndex++;
      } else {
        _showCompletionDialog();
      }
    });

    // 🔓 MỞ KHÓA NÚT BẤM SAU 150ms
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _isProcessingReview = false;
      }
    });
  }

  @override
  void dispose() {
    _feverDrainTimer?.cancel();
    super.dispose();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Text('HOÀN THÀNH BÀI HỌC!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text('Bạn đã hoàn thành ${_currentIndex + 1} thẻ từ vựng.', style: const TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Quay về', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox_rounded, color: Colors.grey, size: 64),
              const SizedBox(height: 16),
              const Text('Không có từ vựng nào trong danh sách!', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              border: Border.all(
                color: _isFeverActive ? Colors.cyanAccent : Colors.transparent,
                width: _isFeverActive ? 4 : 0,
              ),
              boxShadow: _isFeverActive
                  ? [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ]
                  : [],
            ),
            child: SafeArea(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 850),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      FlashcardHeaderProgress(
                        currentIndex: _currentIndex,
                        totalWords: widget.words.length,
                        onBackPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Row(
                          children: [
                            FeverMeterBar(
                              feverValue: _feverValue,
                              isFeverActive: _isFeverActive,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: FlashcardFlipperCard(
                                item: widget.words[_currentIndex],
                                isFlipped: _isFlipped,
                                isFeverActive: _isFeverActive,
                                onTap: () => setState(() => _isFlipped = !_isFlipped),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FlashcardActionButtons(
                        onReview: _handleReview,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _isDamageFlashActive ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFF1744).withOpacity(0.9),
                    width: 12,
                  ),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      Colors.transparent,
                      const Color(0xFFFF1744).withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}