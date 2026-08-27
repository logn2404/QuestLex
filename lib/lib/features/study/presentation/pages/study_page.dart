import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/api_study_repositories.dart';
import '../../domain/enums/study_mode.enum.dart';
import '../widgets/study_header_banner.dart';
import '../widgets/study_mode_toggle.dart';
import '../widgets/study_task_section.dart';
import 'study_controller.dart';

class StudyPage extends StatelessWidget {
  final List<Map<String, dynamic>> initialWords;

  const StudyPage({
    super.key,
    this.initialWords = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudyController(
        repository: ApiStudyRepository(),
        initialWords: initialWords,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1E),
          title: const Text(
            'RÈN LUYỆN TỪ VỰNG',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          centerTitle: true,
          elevation: 2,
        ),
        body: Consumer<StudyController>(
          builder: (context, controller, child) {
            final isStudy = controller.currentMode == StudyMode.study;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOGGLE CHẾ ĐỘ STUDY / PRACTICE
                  StudyModeToggle(
                    currentMode: controller.currentMode,
                    onModeChanged: controller.setMode,
                  ),

                  const SizedBox(height: 16),

                  // 2. BANNER HIỂN THỊ THÔNG BÁO TẢI NGẦM
                  StudyHeaderBanner(
                    mode: controller.currentMode,
                    isGoldenHour: controller.isGoldenHour,
                    expMultiplier: controller.expMultiplier,
                    wordCount: controller.wordCount,
                  ),

                  const SizedBox(height: 24),

                  // 3. TIÊU ĐỀ SECTION
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. DANH SÁCH 3 THẺ BÀI / GAME
                  if (controller.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: Colors.redAccent),
                      ),
                    )
                  else
                    StudyTaskSection(
                      words: controller.studyQueue,
                      onReview: controller.reviewWord,
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