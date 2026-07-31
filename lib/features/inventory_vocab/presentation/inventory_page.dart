import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:questlex/features/learning_vocab/domain/models/vocab_stats.dart';
import 'package:questlex/features/inventory_vocab/data/repositories/fake_inventory_vocab_repository.dart';
import 'package:questlex/features/inventory_vocab/presentation/inventory_controller.dart';
import 'package:questlex/features/inventory_vocab/presentation/widgets/inventory_control_panel.dart';
import 'package:questlex/features/inventory_vocab/presentation/widgets/inventory_search_bar.dart';
import 'package:questlex/features/inventory_vocab/presentation/widgets/profile.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dummyStats = VocabStats(
      levelCounts: const {
        'C2': 120,
        'C1': 450,
        'B2': 350,
        'B1': 210,
        'A2': 95,
        'A1': 40,
      },
    );

    return ChangeNotifierProvider(
      create: (_) => InventoryController(
        repository: FakeInventoryVocabRepository(),
      ),
      child: Scaffold(
        // 🎯 BỎ APPBAR Ở ĐÂY ĐỂ TRÁNH TRÙNG THANH TIÊU ĐỀ
        body: Consumer<InventoryController>(
          builder: (context, controller, child) {
            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🎯 1. HEADER TIÊU ĐỀ CHUẨN (DÀNH SẴN Ô TRỐNG 40x40 CHO FLOATING BACK BUTTON)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                    child: Row(
                      children: [
                        // Ô trống 40x40 cố định nhường chỗ cho nút Back từ MainShellPage
                        const SizedBox(width: 40, height: 40),
                        const SizedBox(width: 12),

                        // Tiêu đề trang (Không bao giờ lo bị đè chữ nữa)
                        Expanded(
                          child: Text(
                            'Kho từ vựng đã thuộc',
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

                  // 🎯 2. NỘI DUNG CHÍNH (CỘT TRÁI & CỘT PHẢI)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. CỘT TRÁI: Profile + Control Panel (Chứa Lối tắt nhanh)
                          SizedBox(
                            width: 260,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Profile(stats: dummyStats),
                                  const SizedBox(height: 12),
                                  const InventoryControlPanel(),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // 2. CỘT PHẢI: Search Bar + Dropdown Sort + Grid Danh Sách Từ
                          Expanded(
                            child: Column(
                              children: [
                                InventorySearchBar(
                                  onSearchChanged: controller.onSearchChanged,
                                  currentSort: controller.selectedSort,
                                  onSortChanged: controller.setSortOption,
                                ),

                                const SizedBox(height: 16),

                                Expanded(
                                  child: controller.isLoading
                                      ? const Center(child: CircularProgressIndicator())
                                      : controller.vocabList.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'Không tìm thấy từ vựng nào!',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                            )
                                          : GridView.builder(
                                              gridDelegate:
                                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                                maxCrossAxisExtent: 260,
                                                mainAxisExtent: 120,
                                                crossAxisSpacing: 12,
                                                mainAxisSpacing: 12,
                                              ),
                                              itemCount: controller.vocabList.length,
                                              itemBuilder: (context, index) {
                                                final item = controller.vocabList[index];
                                                return Card(
                                                  elevation: 1,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                    side: BorderSide(
                                                      color: Theme.of(context)
                                                          .dividerColor
                                                          .withValues(alpha: 0.1),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(12),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                item.word,
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 15,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: Colors.green.withValues(
                                                                  alpha: 0.15,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(6),
                                                              ),
                                                              child: Text(
                                                                item.cefrLevel,
                                                                style: const TextStyle(
                                                                  color: Colors.green,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Text(
                                                          item.meaning,
                                                          style: TextStyle(
                                                            color: Theme.of(context).hintColor,
                                                            fontSize: 13,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const Row(
                                                          children: [
                                                            Icon(
                                                              Icons.verified_rounded,
                                                              color: Colors.green,
                                                              size: 16,
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              '100% Mastered',
                                                              style: TextStyle(
                                                                color: Colors.green,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}