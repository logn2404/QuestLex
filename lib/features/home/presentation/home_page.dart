import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:questlex/features/learning_vocab/presentation/learning_page.dart';
import 'package:questlex/features/inventory_vocab/presentation/inventory_page.dart';
import 'package:questlex/features/home/data/repositories/fake_dashboard_repository.dart';
import 'package:questlex/features/home/presentation/home_controller.dart';
import 'package:questlex/features/home/presentation/trigger_config_controller.dart';
import 'package:questlex/features/home/presentation/widgets/monthly_diff_badge.dart';

import 'package:questlex/screens/widgets/ai_scan_toggle_card.dart';
import 'package:questlex/screens/widgets/dashboard_action_card.dart';
import 'package:questlex/screens/widgets/scan_timer_card.dart';
import 'package:questlex/screens/widgets/trigger_settings_bottom_sheet.dart';
import 'package:questlex/services/game_timer_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;
  late final TriggerConfigController _triggerConfigController;

  @override
  void initState() {
    super.initState();
    _triggerConfigController = TriggerConfigController();
    _controller = HomeController(
      repository: FakeDashboardRepository(),
      timerService: GameTimerService(
        onTick: () {
          if (mounted) {
            _handleControllerChange();
          }
        },
      ),
      triggerConfigController: _triggerConfigController,
    );
    _controller.addListener(_handleControllerChange);
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openTriggerSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: _triggerConfigController,
          child: const TriggerSettingsBottomSheet(),
        );
      },
    );
  }

  Future<bool> _showPrivacyWarningDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: Colors.amber, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Cảnh báo quyền riêng tư',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: const Text(
                'Chương trình sẽ bắt đầu chụp và phân tích mọi hoạt động trên màn hình máy tính của bạn để hỗ trợ quét từ vựng.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Khoan đã', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Đồng ý'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _onToggleScanning(bool value) async {
    if (value) {
      bool confirmed = await _showPrivacyWarningDialog(context);

      if (!mounted) return;

      if (confirmed) {
        _controller.toggleScanning(true);
      } else {
        _controller.toggleScanning(false);
      }
    } else {
      _controller.toggleScanning(false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _controller.stats;

    if (stats == null || _controller.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QuestLex Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 2,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuestLex Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ScanTimerCard(
              isScanningActive: _controller.isScanningActive,
              formattedTime: _controller.formattedTime,
              isExceeding3Hours: _controller.isExceeding3Hours,
            ),
            const SizedBox(height: 12),
            
            AiScanToggleCard(
              isScanningActive: _controller.isScanningActive,
              onChanged: _onToggleScanning,
              onOpenSettings: _openTriggerSettings,
            ),
            
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 650 ? 4 : 2;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    // 1. KHO TỪ VỰNG
                    DashboardActionCard(
                      title: 'KHO TỪ VỰNG',
                      icon: Icons.menu_book_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InventoryPage(),
                          ),
                        );
                      },
                      subContent: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${stats.totalInventoryVocab}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          MonthlyDiffBadge(diff: stats.inventoryMonthlyDiff),
                          const Text(' từ', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),

                    // 2. TỪ VỰNG ĐANG HỌC
                    DashboardActionCard(
                      title: 'TỪ VỰNG ĐANG HỌC',
                      icon: Icons.edit_note_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LearningPage(),
                          ),
                        );
                      },
                      subContent: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${stats.totalLearningVocab}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          MonthlyDiffBadge(diff: stats.learningMonthlyDiff),
                          const Text(' từ', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),

                    // 3. BẮT ĐẦU HỌC
                    DashboardActionCard(
                      title: 'BẮT ĐẦU HỌC',
                      icon: Icons.play_circle_fill_rounded,
                      onTap: () {},
                      subContent: Text(
                        '${stats.pendingVocab} từ đang chờ',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // 4. STREAK
                    DashboardActionCard(
                      title: 'STREAK',
                      icon: Icons.local_fire_department_rounded,
                      onTap: () {},
                      subContent: Column(
                        children: [
                          const Text(
                            'CHUỖI NGÀY HỌC LIÊN TIẾP:',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${stats.streakDays} NGÀY',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}