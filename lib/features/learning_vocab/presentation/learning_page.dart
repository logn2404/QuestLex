import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/fake_learning_vocab_repository.dart';
import 'learning_vocab_controller.dart';
import 'widgets/learning_analytics.dart';
import 'widgets/learning_control_panel.dart';
import 'widgets/word_queue.dart';

class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LearningVocabController(
        repository: FakeLearningVocabRepository(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Từ vựng đang học',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Consumer<LearningVocabController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: controller.leftPanelWidth,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          LearningAnalytics(
                            dailyData: controller.dailyStats,
                            monthlyData: controller.monthlyStats,
                          ),
                          const SizedBox(height: 12),
                          LearningControlPanel(
                            isSelectionMode: controller.isSelectionMode,
                            selectedCount: controller.selectedItemIds.length,
                            onToggleSelection: controller.toggleSelectionMode,
                            onStartLearning: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Bắt đầu học ${controller.selectedItemIds.length} từ vựng đã chọn!',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (details) {
                      controller.updateLeftPanelWidth(details.delta.dx);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                      child: Container(
                        width: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Center(
                          child: Container(
                            width: 4,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: WordQueue(
                      vocabList: controller.vocabList,
                      onSearchChanged: controller.search,
                      isSelectionMode: controller.isSelectionMode,
                      selectedItemIds: controller.selectedItemIds,
                      onItemToggle: controller.toggleSelectItem,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}