import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../learning_vocab/presentation/learning_page.dart';
import '../../../screens/widgets/ai_scan_toggle_card.dart';
import '../../../screens/widgets/dashboard_action_card.dart';
import '../../../screens/widgets/scan_timer_card.dart';
import '../../../services/game_timer_service.dart';
import '../data/repositories/fake_dashboard_repository.dart';
import 'home_controller.dart';
import 'trigger_config_controller.dart';
import '../../../screens/widgets/trigger_settings_bottom_sheet.dart';
import '../../inventory_vocab/presentation/inventory_page.dart';


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

  /// Mở Bảng Cấu hình Trigger
  void _openTriggerSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Cung cấp instance _controller cho BottomSheet thông qua ChangeNotifierProvider.value
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
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
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
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Đồng ý'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Xử lý sự kiện gạt công tắc AI Scan
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
            
            // 🎯 CARD AI SCAN + NÚT SETTINGS TRIGGER
            AiScanToggleCard(
              isScanningActive: _controller.isScanningActive,
              onChanged: _onToggleScanning,
              onOpenSettings: _openTriggerSettings, // 👈 Truyền callback mở Cài đặt
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
                      subContent: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          children: [
                            TextSpan(text: '${stats.totalVocab}('),
                            TextSpan(
                              text: '+${stats.addedVocab}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ') từ'),
                          ],
                        ),
                      ),
                    ),
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
                      subContent: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          children: [
                            TextSpan(text: '${stats.learningVocab}('),
                            TextSpan(
                              text: '${stats.masterChange}',
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ') từ'),
                          ],
                        ),
                      ),
                    ),
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