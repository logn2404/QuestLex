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
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => LearningVocabController(
        repository: FakeLearningVocabRepository(),
      ),
      child: Scaffold(
        // 🎯 1. BỎ APPBAR MẶC ĐỊNH ĐỂ TRÁNH BỊ TRÙNG LẮP TIÊU ĐỀ
        body: Consumer<LearningVocabController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🎯 2. HEADER TIÊU ĐỀ CHUẨN (CÓ Ô TRỐNG 40x40 CHO FLOATING BACK BUTTON)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                    child: Row(
                      children: [
                        // Ô trống 40x40 cố định nhường chỗ cho Nút Back từ MainShellPage
                        const SizedBox(width: 40, height: 40),
                        const SizedBox(width: 12),

                        // Tiêu đề trang (Tự động canh lề chuẩn không bị đè)
                        Expanded(
                          child: Text(
                            'Từ vựng đang học',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🎯 3. NỘI DUNG CHÍNH (CỘT CÓ THỂ RESIZE + RESIZE HANDLE + WORD QUEUE)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CỘT TRÁI: Tiến độ & Control Panel
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

                          // NÚT KÉO RESIZE CỘT TRÁI
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

                          // CỘT PHẢI: WordQueue danh sách từ vựng
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