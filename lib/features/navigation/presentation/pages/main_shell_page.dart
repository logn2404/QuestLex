import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../home/presentation/home_page.dart';
import '../../../inventory_vocab/presentation/inventory_page.dart';
import '../../../learning_vocab/presentation/learning_page.dart';

import '../../domain/app_screen.dart';
import '../controllers/navigation_controller.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

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
                          color: Colors.white.withValues(alpha: 0.08), // Nền mờ chuẩn Dark UI
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

      case AppScreen.streak:
        return _buildStreakComingSoon(context);
    }
  }

  Widget _buildStreakComingSoon(BuildContext context) {
    return Center(
      key: const ValueKey(AppScreen.streak),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 90,
            color: Colors.orangeAccent.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.4),
              ),
            ),
            child: const Text(
              'COMING SOON',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tính năng đang được phát triển!',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => context.read<NavigationController>().resetToHome(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.home_outlined, size: 18),
            label: const Text('Về Trang Chủ'),
          ),
        ],
      ),
    );
  }
}