import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_capturer/screen_capturer.dart';

class ScreenCaptureService {
  /// Kiểm tra và xin quyền chụp màn hình (macOS)
  Future<bool> checkPermission() async {
    bool hasAccess = await ScreenCapturer.instance.isAccessAllowed();
    if (!hasAccess && Platform.isMacOS) {
      await ScreenCapturer.instance.requestAccess();
    }
    return hasAccess;
  }

  /// Thực hiện chụp toàn bộ màn hình và lưu thành file PNG tạm
  Future<String?> captureEntireScreen() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.png';

      CapturedData? capturedData = await ScreenCapturer.instance.capture(
        mode: CaptureMode.screen, // ✅ Fix Bug #3: Dùng CaptureMode.screen
        imagePath: filePath,
        silent: true,
      );

      if (capturedData != null && capturedData.imagePath != null) {
        debugPrint('📸 Đã chụp màn hình: ${capturedData.imagePath}');
        return capturedData.imagePath;
      }
    } catch (e) {
      debugPrint('❌ Lỗi chụp màn hình: $e');
    }
    return null;
  }
}