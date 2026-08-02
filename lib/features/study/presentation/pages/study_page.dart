import 'package:flutter/material.dart';

import 'package:questlex/features/study/domain/enums/study_mode.enum.dart';
import 'package:questlex/features/study/presentation/widgets/study_header_banner.dart';
import 'package:questlex/features/study/presentation/widgets/study_mode_toggle.dart';
import 'package:questlex/features/study/presentation/widgets/study_task_section.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  StudyMode currentMode = StudyMode.study;

  // Giả lập trạng thái Giờ vàng (Golden Hour)
  final bool isGoldenHour = true;
  final double expMultiplier = 1.5;

  @override
  Widget build(BuildContext context) {
    final isStudy = currentMode == StudyMode.study;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RÈN LUYỆN TỪ VỰNG',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SWITCH TOGGLE (STUDY / PRACTICE)
            StudyModeToggle(
              currentMode: currentMode,
              onModeChanged: (mode) => setState(() => currentMode = mode),
            ),

            const SizedBox(height: 16),

            // 2. BANNER GIỜ VÀNG / SINH TỒN
            StudyHeaderBanner(
              mode: currentMode,
              isGoldenHour: isGoldenHour,
              expMultiplier: expMultiplier,
            ),

            const SizedBox(height: 24),

            // 3. TIÊU ĐỀ
            Row(
              children: [
                Icon(
                  isStudy ? Icons.auto_awesome : Icons.local_fire_department_rounded,
                  color: isStudy ? Colors.amberAccent : Colors.deepOrangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isStudy ? 'CHỌN HÌNH THỨC RÈN LUYỆN' : 'CHẾ ĐỘ SINH TỒN VÔ HẠN',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 4. BỘ 3 THẺ BÀI TỰ CÓ HOVER GLOW & TRANSITION MỚI
            const StudyTaskSection(),
          ],
        ),
      ),
    );
  }
}