import 'package:flutter/material.dart';
import '../../domain/app_screen.dart';

class NavigationController extends ChangeNotifier {
  // Mảng lưu lịch sử điều hướng, mặc định luôn bắt đầu từ Home
  final List<AppScreen> _history = [AppScreen.home];

  AppScreen get currentScreen => _history.last;

  /// Kiểm tra xem có thể quay lại trang trước hay không (Nếu mảng > 1 item)
  bool get canGoBack => _history.length > 1;

  /// 🚀 CHUYỂN TRANG THÔNG MINH (Smart Re-order Stack)
  void navigateTo(AppScreen screen) {
    // 1. Nếu đang ở đúng trang đó rồi thì không làm gì cả
    if (_history.last == screen) return;

    // 2. Nếu chuyển về Home, reset toàn bộ mảng về [AppScreen.home]
    if (screen == AppScreen.home) {
      resetToHome();
      return;
    }

    // 3. 🎯 NẾU TRANG ĐÃ TỒN TẠI TRONG STACK (Ví dụ: Inventory):
    // Rút nó ra khỏi vị trí cũ để tránh bị nhân bản/clone
    _history.removeWhere((item) => item == screen);

    // 4. Đẩy trang đó lên vị trí trên cùng của Stack
    _history.add(screen);

    notifyListeners();
  }

  /// Quay lại trang trước đó trong lịch sử
  void goBack() {
    if (canGoBack) {
      _history.removeLast();
      notifyListeners();
    }
  }

  /// Reset toàn bộ mảng về lại Trang Chủ (Home)
  void resetToHome() {
    _history.clear();
    _history.add(AppScreen.home);
    notifyListeners();
  }
}