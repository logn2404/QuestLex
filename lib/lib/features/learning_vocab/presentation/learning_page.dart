import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/api_learning_vocab_repository.dart';
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
        repository: ApiLearningVocabRepository(),
      ),
      child: const _LearningPageBody(),
    );
  }
}

class _LearningPageBody extends StatefulWidget {
  const _LearningPageBody();

  @override
  State<_LearningPageBody> createState() => _LearningPageBodyState();
}

class _LearningPageBodyState extends State<_LearningPageBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safelyLoadData();
    });
  }

  Future<void> _safelyLoadData() async {
    final controller = context.read<LearningVocabController>();
    try {
      await controller.loadData();
    } catch (error) {
      if (!mounted) return;

      // 1. Tự động reset quay về Trang Chủ
      Navigator.of(context).popUntil((route) => route.isFirst);

      // 2. Hiện Dialog thông báo nguyên nhân lỗi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.amberAccent, size: 28),
              SizedBox(width: 10),
              Text(
                'Lỗi kết nối Backend',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Không thể truy cập API Backend từ vựng đang học.\n\nChi tiết lỗi: $error\n\nHãy đảm bảo server Python FastAPI (api_server.py) đã được bật ở cổng 8000.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<LearningVocabController>();

    if (controller.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF12121D),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF12121D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  const SizedBox(width: 40, height: 40),
                  const SizedBox(width: 12),
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

            // NỘI DUNG CHÍNH (CỘT TRÁI + RESIZE HANDLE + WORD QUEUE)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cột trái
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

                    // Thanh Kéo Resize Cột Trái
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

                    // Cột phải: WordQueue có sẵn của bạn
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
      ),
    );
  }
}