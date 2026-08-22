import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/api_inventory_vocab_repository.dart';
import 'inventory_controller.dart';
import 'widgets/inventory_control_panel.dart';
import 'widgets/inventory_search_bar.dart';
import 'widgets/inventory_vocab_card.dart';
import 'widgets/profile.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => InventoryController(
        repository: ApiInventoryVocabRepository(
          baseUrl: 'http://127.0.0.1:8000',
        ),
      ),
      child: Scaffold(
        body: Consumer<InventoryController>(
          builder: (context, controller, child) {
            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🎯 1. HEADER TIÊU ĐỀ
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                    child: Row(
                      children: [
                        const SizedBox(width: 40, height: 40),
                        const SizedBox(width: 12),
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
                          // 1. CỘT TRÁI: Profile (Lấy stats thật từ DB) + Control Panel
                          SizedBox(
                            width: 260,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Profile(stats: controller.stats), // 🎯 Stats động tính từ DB!
                                  const SizedBox(height: 12),
                                  const InventoryControlPanel(),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // 2. CỘT PHẢI: Search Bar + Grid Danh Sách Từ
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
                                  child: _buildVocabGrid(controller),
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

  // Hàm render GridView tách biệt gọn gàng
  Widget _buildVocabGrid(InventoryController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.vocabList.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy từ vựng nào!',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 130,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: controller.vocabList.length,
      itemBuilder: (context, index) {
        return InventoryVocabCard(item: controller.vocabList[index]);
      },
    );
  }
}