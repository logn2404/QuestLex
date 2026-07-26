import 'package:flutter/material.dart';
import '../../learning_vocab/domain/models/vocab_stats.dart';
import 'widgets/profile.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data tạm thời để giữ UI Profile
    const dummyStats = VocabStats(
      overallScore: 61,
      starRating: 4,
      currentExp: 65.0,
      maxExp: 100.0,
      levelCounts: {
        'C2': 120,
        'C1': 450,
        'B2': 350,
        'B1': 210,
        'A2': 95,
        'A1': 40,
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho từ vựng đã thuộc', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cột trái Profile (Đã lưu trữ an toàn)
            Profile(stats: dummyStats),
            SizedBox(width: 16),
            // Phần danh sách từ đã thuộc sẽ phát triển sau ở đây
            Expanded(
              child: Center(
                child: Text('Danh sách kho từ vựng (Inventory) sẽ làm sau ở đây'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}