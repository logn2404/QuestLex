import 'package:flutter/material.dart';
import 'typing_header_progress.dart';
import 'typing_definition_card.dart';
import 'typing_input_section.dart';
import 'typing_action_buttons.dart';

class WordTypingSessionView extends StatefulWidget {
  final List<Map<String, dynamic>> words;
  final Function(String word, int quality) onReview;
  final VoidCallback onFinished;

  const WordTypingSessionView({
    super.key,
    required this.words,
    required this.onReview,
    required this.onFinished,
  });

  @override
  State<WordTypingSessionView> createState() => _WordTypingSessionViewState();
}

class _WordTypingSessionViewState extends State<WordTypingSessionView> {
  int _currentIndex = 0;
  int _hintCountLeft = 3;
  int _currentQuality = 3;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<bool> _revealedChars = [];
  bool _isAnswered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentWord();
  }

  void _loadCurrentWord() {
    if (_currentIndex >= widget.words.length) {
      widget.onFinished();
      return;
    }

    final targetWord = _targetWord;
    _hintCountLeft = 3;
    _currentQuality = 3;
    _isAnswered = false;
    _isCorrect = false;
    _textController.clear();
    _revealedChars = List.generate(targetWord.length, (_) => false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  String get _targetWord =>
      (widget.words[_currentIndex]['word'] ?? '').toString().trim().toLowerCase();

  String get _definition {
    final item = widget.words[_currentIndex];
    return (item['vietnamese_meaning'] ??
            item['meaning_vi'] ??
            item['viMeaning'] ??
            item['meaning'] ??
            item['definition'] ??
            'Chưa có nghĩa tiếng Việt')
        .toString();
  }

  void _onHintPressed() {
    if (_hintCountLeft <= 0 || _isAnswered) return;

    final target = _targetWord;
    List<int> unrevealedIndices = [];
    for (int i = 0; i < target.length; i++) {
      if (!_revealedChars[i] && target[i] != ' ') {
        unrevealedIndices.add(i);
      }
    }

    if (unrevealedIndices.isEmpty) return;

    int charsToReveal = target.length > 5 ? 2 : 1;
    unrevealedIndices.shuffle();

    setState(() {
      for (int i = 0; i < charsToReveal && i < unrevealedIndices.length; i++) {
        _revealedChars[unrevealedIndices[i]] = true;
      }
      _hintCountLeft--;
      if (_currentQuality > 1) {
        _currentQuality--;
      }
    });
  }

  void _handleSubmit() {
    if (_isAnswered) {
      _nextWord();
      return;
    }

    final input = _textController.text.trim().toLowerCase();
    if (input.isEmpty) return;

    final isRight = input == _targetWord;

    setState(() {
      _isAnswered = true;
      _isCorrect = isRight;
    });

    final finalQuality = isRight ? _currentQuality : 1;
    _currentQuality = finalQuality;
    widget.onReview(_targetWord, finalQuality);
  }

  void _onGiveUp() {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = false;
      _revealedChars = List.generate(_targetWord.length, (_) => true);
    });

    widget.onReview(_targetWord, 1);
  }

  void _nextWord() {
    setState(() {
      _currentIndex++;
      _loadCurrentWord();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.words.length) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: SafeArea(
        child: Column(
          children: [
            TypingHeaderProgress(
              currentIndex: _currentIndex,
              totalWords: widget.words.length,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    TypingDefinitionCard(definition: _definition),
                    const SizedBox(height: 30),
                    const Divider(color: Colors.white24, thickness: 1.5),
                    const SizedBox(height: 30),
                    TypingInputSection(
                      targetWord: _targetWord,
                      revealedChars: _revealedChars,
                      hintCountLeft: _hintCountLeft,
                      isAnswered: _isAnswered,
                      textController: _textController,
                      focusNode: _focusNode,
                      currentWordLength: _targetWord.length,
                      onHintPressed: _onHintPressed,
                      onSubmit: _handleSubmit,
                    ),
                    const SizedBox(height: 20),
                    if (_isAnswered) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isCorrect ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _isCorrect ? Colors.green : Colors.red),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isCorrect ? Icons.check_circle : Icons.cancel,
                                color: _isCorrect ? Colors.green : Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              _isCorrect
                                  ? 'Chính xác! (+$_currentQuality Mastery)'
                                  : 'Đáp án đúng: ${_targetWord.toUpperCase()}',
                              style: TextStyle(
                                color: _isCorrect ? Colors.greenAccent : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 20),
                    TypingActionButtons(
                      isAnswered: _isAnswered,
                      onGiveUp: _onGiveUp,
                      onSubmit: _handleSubmit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}