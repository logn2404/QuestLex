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
  List<MatchingTileData> _vietnameseTiles = [];
  List<MatchingTileData> _englishTiles = [];
  MatchingTileData? _firstSelected;
  bool _isProcessing = false;
  int _matchedPairsCount = 0;
  int _sectionIndex = 0;
  final Stopwatch _pairTimer = Stopwatch();
  Timer? _syncDrainTimer;

  double _syncValue = 0.0;
  bool _isSyncActive = false;
  bool _isDamageFlashActive = false;

  @override
  void initState() {
    super.initState();
    _initializeTiles();
  }

  void _initializeTiles() {
    if (widget.words.isEmpty) return;

    final vietnameseTiles = <MatchingTileData>[];
    final englishTiles = <MatchingTileData>[];
    final start = _sectionIndex * 6;
    final end = start + 6 > widget.words.length
      ? widget.words.length
      : start + 6;
    final sessionWords = widget.words.sublist(start, end);

    for (int i = 0; i < sessionWords.length; i++) {
      final item = sessionWords[i];
      final wordStr = item['word']?.toString() ?? '';
      final vietnameseMeaning = _shortVietnameseMeaning(item);

      vietnameseTiles.add(MatchingTileData(
        id: 'vi_$i',
        text: vietnameseMeaning,
        matchGroup: wordStr,
        isWord: false,
      ));

      englishTiles.add(MatchingTileData(
        id: 'en_$i',
        text: wordStr.toUpperCase(),
        matchGroup: wordStr,
        isWord: true,
      ));
    }

    vietnameseTiles.shuffle();
    englishTiles.shuffle();
    _vietnameseTiles = vietnameseTiles;
    _englishTiles = englishTiles;
    _tiles = [...vietnameseTiles, ...englishTiles];
    _pairTimer
      ..reset()
      ..start();
  }

  String _shortVietnameseMeaning(Map<String, dynamic> item) {
    final rawMeaning = (item['vietnamese_meaning'] ??
            item['meaning_vi'] ??
            item['viMeaning'] ??
            item['meaning'] ??
            'Chưa có nghĩa tiếng Việt')
        .toString()
        .trim();
    if (rawMeaning.isEmpty) return 'Chưa có nghĩa tiếng Việt';

    final firstMeaning = rawMeaning.split(RegExp(r'[,;/|]')).first.trim();
    final words = firstMeaning.split(RegExp(r'\s+'));
    return words.length <= 5 ? firstMeaning : words.take(5).join(' ');
  }

  void _triggerDamageFlash() {
    setState(() => _isDamageFlashActive = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isDamageFlashActive = false);
    });
  }

  void _activateSyncMode() {
    _syncDrainTimer?.cancel();
    setState(() {
      _syncValue = 1.0;
      _isSyncActive = true;
    });

    const tickMs = 50;
    final totalSeconds = (widget.words.length / 2).clamp(4.0, 30.0);
    final decrementPerTick = 1.0 / ((totalSeconds * 1000) / tickMs);

    _syncDrainTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _syncValue -= decrementPerTick;
        if (_syncValue <= 0.0) {
          _syncValue = 0.0;
          _isSyncActive = false;
          timer.cancel();
        }
      });
    });
  }

  void _onTileTap(MatchingTileData tile) {
    if (_isProcessing || tile.isMatched) return;

    if (tile.isSelected) {
      setState(() {
        tile.isSelected = false;
        _firstSelected = null;
      });
      _pairTimer
        ..reset()
        ..start();
      return;
    }

    setState(() => tile.isSelected = true);

    if (_firstSelected == null) {
      _firstSelected = tile;
    } else {
      _isProcessing = true;
      final secondSelected = tile;

      if (_firstSelected!.matchGroup == secondSelected.matchGroup) {
        final quality = _isSyncActive ? 4 : _qualityForElapsedTime();
        _pairTimer.stop();
        DamageIndicator.show(
          context,
          text: _isSyncActive
              ? '+${_expForQuality(quality)} EXP (SYNC)'
              : '+${_expForQuality(quality)} EXP',
          color: const Color(0xFF00E5FF),
        );

        widget.onReview(_firstSelected!.matchGroup, quality);

        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          final shouldActivateSync = !_isSyncActive;
          setState(() {
            _firstSelected!.isMatched = true;
            secondSelected.isMatched = true;
            _firstSelected!.isSelected = false;
            secondSelected.isSelected = false;
            _firstSelected = null;
            _isProcessing = false;
            _matchedPairsCount++;

            if (shouldActivateSync) {
              _syncValue = (_syncValue + 0.20).clamp(0.0, 1.0);
            }

            if (_matchedPairsCount < (_tiles.length / 2)) {
              _pairTimer
                ..reset()
                ..start();
            }
          });
          if (shouldActivateSync && _syncValue >= 1.0) {
            _activateSyncMode();
          }
          if (_matchedPairsCount >= (_tiles.length / 2)) {
            if (_sectionIndex + 1 < _sectionCount) {
              setState(() {
                _sectionIndex++;
                _matchedPairsCount = 0;
                _firstSelected = null;
                _isProcessing = false;
                _initializeTiles();
              });
            } else {
              _showCompletionDialog();
            }
          }
        });
      } else {
        final isProtected = _isSyncActive;
        _pairTimer.stop();
        _triggerDamageFlash();
        DamageIndicator.show(
          context,
          text: isProtected ? '-5 EXP (PROTECTED)' : '-10 EXP',
          color: const Color(0xFFFF5252),
        );

        widget.onReview(_firstSelected!.matchGroup, 1);
        setState(() {
          _syncValue = (_syncValue - (isProtected ? 0.125 : 0.25)).clamp(0.0, 1.0);
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _firstSelected!.isSelected = false;
            secondSelected.isSelected = false;
            _firstSelected = null;
            _isProcessing = false;
            _pairTimer
              ..reset()
              ..start();
          });
        });
      }
    }
  }

  int _qualityForElapsedTime() {
    final elapsedSeconds = _pairTimer.elapsedMilliseconds / 1000.0;
    if (elapsedSeconds <= 5) return 4;
    if (elapsedSeconds <= 10) return 3;
    return 2;
  }

  int _expForQuality(int quality) {
    switch (quality) {
      case 4:
        return 25;
      case 3:
        return 15;
      case 2:
        return 5;
      case 1:
        return -10;
      default:
        return 0;
    }
  }

  int get _sectionCount => (widget.words.length + 5) ~/ 6;

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
                  const SizedBox(height: 4),
                  Text(
                    'SECTION ${_sectionIndex + 1}/$_sectionCount',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildMatchingColumn(
                                      title: 'TIẾNG VIỆT',
                                      tiles: _vietnameseTiles,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMatchingColumn(
                                      title: 'TỪ ENGLISH',
                                      tiles: _englishTiles,
                                    ),
                                  ),
                                ],
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

  @override
  void dispose() {
    _pairTimer.stop();
    _syncDrainTimer?.cancel();
    super.dispose();
  }

  Widget _buildMatchingColumn({
    required String title,
    required List<MatchingTileData> tiles,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            for (var index = 0; index < tiles.length; index++) ...[
              if (index > 0) const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: MatchingTileCard(
                  tile: tiles[index],
                  isFeverActive: _isSyncActive,
                  onTap: () => _onTileTap(tiles[index]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}