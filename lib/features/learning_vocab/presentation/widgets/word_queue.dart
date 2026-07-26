import 'package:flutter/material.dart';
import '../../domain/models/learning_vocab_item.dart';
import 'search_bar.dart';
import 'word_card.dart';

class WordQueue extends StatelessWidget {
  final List<LearningVocabItem> vocabList;
  final ValueChanged<String> onSearchChanged;
  final bool isSelectionMode;
  final Set<String> selectedItemIds;
  final ValueChanged<String>? onItemToggle;

  const WordQueue({
    super.key,
    required this.vocabList,
    required this.onSearchChanged,
    this.isSelectionMode = false,
    this.selectedItemIds = const {},
    this.onItemToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: CustomSearchBar(onChanged: onSearchChanged),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisExtent: 140,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: vocabList.length,
              itemBuilder: (context, index) {
                final item = vocabList[index];
                final isSelected = selectedItemIds.contains(item.id);

                return WordCard(
                  item: item,
                  isSelectionMode: isSelectionMode,
                  isSelected: isSelected,
                  onTap: isSelectionMode ? () => onItemToggle?.call(item.id) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}