import 'package:flutter/material.dart';
import '../services/game_timer_service.dart';
import '../repositories/vocab_repositories.dart'; // Nếu bạn đổi tên file repository thì sửa đúng tên ở đây nhé
import 'widgets/scan_timer_card.dart';
import 'widgets/ai_scan_toggle_card.dart';
import 'widgets/stat_card.dart';
import 'widgets/vocab_list_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isScanningActive = false;

  late final GameTimerService _timerService;
  late final VocabRepository _vocabRepository;

  @override
  void initState() {
    super.initState();
    _vocabRepository = VocabRepository();
    _timerService = GameTimerService(
      onTick: () => setState(() {}), // Cập nhật lại UI mỗi giây đếm
    );
  }

  void _onToggleScanning(bool value) {
    setState(() {
      _isScanningActive = value;
    });

    if (_isScanningActive) {
      _timerService.start();
    } else {
      _timerService.stop();
    }
  }

  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final learningList = _vocabRepository.getLearningVocabs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuestLex Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thẻ đếm thời gian Game Scan
            ScanTimerCard(
              isScanningActive: _isScanningActive,
              formattedTime: _timerService.formattedTime,
              isExceeding3Hours: _timerService.isExceeding3Hours,
            ),
            const SizedBox(height: 16),

            // 2. Nút Toggle AI Scan
            AiScanToggleCard(
              isScanningActive: _isScanningActive,
              onChanged: _onToggleScanning,
            ),
            const SizedBox(height: 24),

            // 3. Kho từ vựng (Statistics)
            const Text('Kho Từ Vựng (Vocab Repository)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Tổng từ tích lũy',
                    count: _vocabRepository.totalVocabCount.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Đã thành thạo',
                    count: _vocabRepository.masteredVocabCount.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.tealAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Từ vựng học tập
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Từ Vựng Học Tập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
              ],
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: learningList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: VocabListTile(vocab: learningList[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}