import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../home/presentation/home_page.dart';
import '../../../inventory_vocab/presentation/inventory_page.dart';
import '../../../learning_vocab/presentation/learning_page.dart';
import '../../../streak/presentation/streak_page.dart';
import '../../../study/presentation/pages/study_page.dart';

import '../../domain/app_screen.dart';
import '../controllers/navigation_controller.dart';
import '../../../../services/screen_capture_service.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  final ScreenCaptureService _captureService = ScreenCaptureService();

  @override
  void initState() {
    super.initState();
    _captureService.startShortcutListener();
  }

  @override
  void dispose() {
    _captureService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationController>();
    final currentScreen = nav.currentScreen;
    final bool isSubPage = currentScreen != AppScreen.home;

    return PopScope(
      canPop: !nav.canGoBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && nav.canGoBack) {
          nav.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Stack(
          children: [
            // 1. MÀN HÌNH CHÍNH
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildScreen(context, currentScreen),
            ),

            // 2. FLOATING BACK BUTTON (CHỈ HIỆN KHI Ở TRANG PHỤ)
            if (isSubPage)
              Positioned(
                top: 12,
                left: 12,
                child: SafeArea(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => nav.goBack(),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen(BuildContext context, AppScreen screen) {
    switch (screen) {
      case AppScreen.home:
        return const HomePage(key: ValueKey(AppScreen.home));

      case AppScreen.inventory:
        return const InventoryPage(key: ValueKey(AppScreen.inventory));

      case AppScreen.learning:
        return const LearningPage(key: ValueKey(AppScreen.learning));

      case AppScreen.study:
        return const StudyPage(key: ValueKey(AppScreen.study));

      case AppScreen.streak:
        return const StreakPage(key: ValueKey(AppScreen.streak));

    }
  }
}