import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/fake_streak_repository.dart';
import 'streak_controller.dart';

import 'widgets/exp_circle.dart';
import 'widgets/fast_switch_card.dart';
import 'widgets/milestone_bar.dart';
import 'widgets/mode_switcher.dart';
import 'widgets/stage_content.dart';
import 'widgets/utility.dart';

class StreakPage extends StatelessWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StreakController(repository: FakeStreakRepository()),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Consumer<StreakController>(
            builder: (context, controller, child) {
              if (controller.isLoading || controller.streakData == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                );
              }

              final data = controller.streakData!;

              return Column(
                children: [
                  // Header dành chỗ trống cho Floating Back Button từ MainShell
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 16, 12),
                    child: Row(
                      children: [
                        SizedBox(width: 40, height: 40),
                        SizedBox(width: 12),
                        Text(
                          'Chuỗi ngày học (Streak)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Content Layout
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---------------- CỘT TRÁI (LEFT PANEL) ----------------
                          SizedBox(
                            width: 280,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  ExpCircle(data: data),
                                  const SizedBox(height: 16),
                                  MilestoneBar(data: data),
                                  const SizedBox(height: 12),
                                  Utility(data: data),
                                  const SizedBox(height: 12),
                                  const FastSwitchCard(),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // ---------------- CỘT PHẢI (RIGHT PANEL) ----------------
                          Expanded(
                            child: Column(
                              children: [
                                ModeSwitcher(controller: controller),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: StageContent(controller: controller),
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
              );
            },
          ),
        ),
      ),
    );
  }
}