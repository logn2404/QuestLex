import 'dart:async';
import 'package:flutter/material.dart';

import '../flashcard/damage_indicator.dart';
import '../flashcard/flashcard_header_progress.dart';
import 'matching_tile_card.dart';
import 'synchronize_meter_bar.dart';

class MatchingCardSessionView extends StatefulWidget {
  final List<Map<String, dynamic>> words;
  final Function(String word, int quality) onReview;

  const MatchingCardSessionView({
    super.key,
    required this.words,
    required this.onReview,
  });

  @override
  State<MatchingCardSessionView> createState() => _MatchingCardSessionViewState();
}

class _MatchingCardSessionViewState extends State<MatchingCardSessionView> {
  List<MatchingTileData> _tiles = [];
  MatchingTileData? _firstSelected;
  bool _isProcessing = false;
  int _matchedPairsCount = 0;

  double _syncValue = 0.0;
  final bool _isSyncActive = false;
  bool _isDamageFlashActive = false;

  @override
  void initState() {
    super.initState();
    _initializeTiles();
  }

  void _initializeTiles() {
    if (widget.words.isEmpty) return;

    List<MatchingTileData> generated = [];
    final sessionWords = widget.words.take(6).toList();

    for (int i = 0; i < sessionWords.length; i++) {
      final item = sessionWords[i];
      final wordStr = item['word'] ?? '';
      final meaningStr = item['definition'] ?? item['meaning'] ?? 'Nghĩa';

      generated.add(MatchingTileData(
        id: 'w_$i',
        text: wordStr.toUpperCase(),
        matchGroup: wordStr,
        isWord: true,
      ));

      generated.add(MatchingTileData(
        id: 'm_$i',
        text: meaningStr,
        matchGroup: wordStr,
        isWord: false,
      ));
    }

    generated.shuffle();
    _tiles = generated;
  }

  void _triggerDamageFlash() {
    setState(() => _isDamageFlashActive = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isDamageFlashActive = false);
    });
  }

  void _onTileTap(MatchingTileData tile) {
    if (_isProcessing || tile.isMatched || tile.isSelected) return;

    setState(() => tile.isSelected = true);

    if (_firstSelected == null) {
      _firstSelected = tile;
    } else {
      _isProcessing = true;
      final secondSelected = tile;

      if (_firstSelected!.matchGroup == secondSelected.matchGroup) {
        DamageIndicator.show(
          context,
          text: '+15 EXP',
          color: const Color(0xFF00E5FF),
        );

        widget.onReview(_firstSelected!.matchGroup, 3);

        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          setState(() {
            _firstSelected!.isMatched = true;
            secondSelected.isMatched = true;
            _firstSelected!.isSelected = false;
            secondSelected.isSelected = false;
            _firstSelected = null;
            _isProcessing = false;
            _matchedPairsCount++;

            _syncValue = (_syncValue + 0.20).clamp(0.0, 1.0);

            if (_matchedPairsCount >= (_tiles.length / 2)) {
              _showCompletionDialog();
            }
          });
        });
      } else {
        _triggerDamageFlash();
        DamageIndicator.show(context, text: '-10 EXP', color: const Color(0xFFFF5252));

        widget.onReview(_firstSelected!.matchGroup, 1);
        _syncValue = (_syncValue - 0.25).clamp(0.0, 1.0);

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _firstSelected!.isSelected = false;
            secondSelected.isSelected = false;
            _firstSelected = null;
            _isProcessing = false;
          });
        });
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A1218),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.extension_rounded, color: Color(0xFF00E5FF), size: 28),
            SizedBox(width: 10),
            Text('ĐỒNG BỘ HOÀN TẤT!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text('Tất cả các thẻ bài đã được ghép thành công.', style: TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Quay về', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 MÀN HÌNH BÁO RỖNG & NÚT QUAY LẠI KHI KHÔNG CÓ TỪ VỰNG (GIỐNG FLASHCARD)
    if (widget.words.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF040709),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox_rounded, color: Colors.grey, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Không có từ vựng nào trong danh sách!',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF040709),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  FlashcardHeaderProgress(
                    currentIndex: _matchedPairsCount,
                    totalWords: (_tiles.length / 2).round(),
                    onBackPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      children: [
                        SynchronizeMeterBar(
                          syncValue: _syncValue,
                          isSyncActive: _isSyncActive,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.2,
                            ),
                            itemCount: _tiles.length,
                            itemBuilder: (context, index) {
                              return MatchingTileCard(
                                tile: _tiles[index],
                                isFeverActive: _isSyncActive,
                                onTap: () => _onTileTap(_tiles[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _isDamageFlashActive ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFF1744).withValues(alpha: 0.9), width: 12),
                  gradient: RadialGradient(
                    colors: [Colors.transparent, const Color(0xFFFF1744).withValues(alpha: 0.4)],
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