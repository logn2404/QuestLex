import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:win32/win32.dart';

/// Hàm mã hóa PNG & lưu đĩa chạy độc lập trên Background Thread (Isolate)
Future<void> _encodeAndSavePngInBackground(Map<String, dynamic> params) async {
  final int width = params['width'];
  final int height = params['height'];
  final Uint8List bytes = params['bytes'];
  final String filePath = params['filePath'];

  final image = img.Image(width: width, height: height);

  for (int i = 0; i < width * height; i++) {
    final offset = i * 4;
    final b = bytes[offset];
    final g = bytes[offset + 1];
    final r = bytes[offset + 2];
    final a = bytes[offset + 3];

    final x = i % width;
    final y = i ~/ width;
    image.setPixelRgba(x, y, r, g, b, a);
  }

  final pngBytes = img.encodePng(image);
  final File newFile = File(filePath);
  await newFile.writeAsBytes(pngBytes);
}

class ScreenCaptureService {
  Directory? _customCaptureDir;
  final List<File> _capturedFiles = [];
  static const int _maxKeepCount = 10;

  /// 🎯 Trỏ chính xác đến thư mục images/ ở Root Project (QuestLex/images/)
  Future<Directory> _getCaptureDirectory() async {
    if (_customCaptureDir != null && await _customCaptureDir!.exists()) {
      return _customCaptureDir!;
    }

    Directory currentDir = Directory.current;
    Directory targetImagesDir;

    // Kiểm tra xem Flutter có đang chạy từ thư mục con (ví dụ 'questlex') hay không
    // Nếu có, lùi ra 1 cấp thư mục cha (parent) để vào gốc QuestLex/
    if (currentDir.path.toLowerCase().endsWith('questlex') && currentDir.parent.existsSync()) {
      targetImagesDir = Directory('${currentDir.parent.path}${Platform.pathSeparator}images');
    } else {
      // Trường hợp đứng sẵn ở Root Project
      targetImagesDir = Directory('${currentDir.path}${Platform.pathSeparator}images');
    }

    if (!await targetImagesDir.exists()) {
      await targetImagesDir.create(recursive: true);
      debugPrint('📂 [ScreenCaptureService]: Đã tạo thư mục images dùng chung tại: ${targetImagesDir.path}');
    }

    _customCaptureDir = targetImagesDir;
    debugPrint('📍 [SCREEN CAPTURE PATH]: ${targetImagesDir.absolute.path}');
    return targetImagesDir;
  }

  void setCustomDirectory(Directory dir) {
    _customCaptureDir = dir;
  }

  Future<bool> checkPermission() async {
    return true;
  }

  /// 🚀 Chụp màn hình bằng Win32 GDI + Mã hóa Isolate Background
  Future<String?> captureEntireScreen() async {
    try {
      final Directory saveDir = await _getCaptureDirectory();
      final String filePath = '${saveDir.path}${Platform.pathSeparator}scan_${DateTime.now().millisecondsSinceEpoch}.png';

      // 1. Lấy kích thước màn hình
      final hdcScreen = GetDC(0);
      final width = GetSystemMetrics(SM_CXSCREEN);
      final height = GetSystemMetrics(SM_CYSCREEN);

      if (width <= 0 || height <= 0) {
        debugPrint('❌ [Win32 Error]: Không lấy được kích thước màn hình ($width x $height)');
        ReleaseDC(0, hdcScreen);
        return null;
      }

      // 2. Tạo Device Context & Bitmap
      final hdcMem = CreateCompatibleDC(hdcScreen);
      final hBitmap = CreateCompatibleBitmap(hdcScreen, width, height);
      final hOld = SelectObject(hdcMem, hBitmap);

      // 3. BitBlt lấy Pixel
      BitBlt(hdcMem, 0, 0, width, height, hdcScreen, 0, 0, SRCCOPY);

      // 4. Trích xuất dữ liệu thô
      final bmi = calloc<BITMAPINFO>();
      bmi.ref.bmiHeader.biSize = sizeOf<BITMAPINFOHEADER>();
      bmi.ref.bmiHeader.biWidth = width;
      bmi.ref.bmiHeader.biHeight = -height;
      bmi.ref.bmiHeader.biPlanes = 1;
      bmi.ref.bmiHeader.biBitCount = 32;
      bmi.ref.bmiHeader.biCompression = BI_RGB;

      final pixelBuffer = calloc<Uint8>(width * height * 4);
      GetDIBits(hdcMem, hBitmap, 0, height, pixelBuffer, bmi, DIB_RGB_COLORS);

      final Uint8List rawBytes = Uint8List.fromList(pixelBuffer.asTypedList(width * height * 4));

      // Dọn dẹp C++ Memory
      free(bmi);
      free(pixelBuffer);
      SelectObject(hdcMem, hOld);
      DeleteObject(hBitmap);
      DeleteDC(hdcMem);
      ReleaseDC(0, hdcScreen);

      // ⚡ 5. Đẩy sang Background Isolate mã hóa & lưu file
      await compute(_encodeAndSavePngInBackground, {
        'width': width,
        'height': height,
        'bytes': rawBytes,
        'filePath': filePath,
      });

      final File newFile = File(filePath);
      if (await newFile.exists()) {
        _capturedFiles.add(newFile);
        debugPrint('📸 [Chụp & Lưu Thành Công]: ${newFile.path}');
        await _cleanOldCaptures();
      }

      return filePath;
    } catch (e) {
      debugPrint('❌ [Win32 Capture Error]: $e');
      return null;
    }
  }

  /// 🧹 Giới hạn giữ tối đa 10 ảnh cũ trong folder
  Future<void> _cleanOldCaptures() async {
    while (_capturedFiles.length > _maxKeepCount) {
      final File oldFile = _capturedFiles.removeAt(0);
      try {
        if (await oldFile.exists()) {
          await oldFile.delete();
          debugPrint('🗑️ [Xóa ảnh cũ]: ${oldFile.path}');
        }
      } catch (e) {
        debugPrint('⚠️ [Lỗi xóa file]: $e');
      }
    }
  }

  /// 🧹 Dọn dẹp sạch folder images/
  Future<void> clearAllCaptures() async {
    try {
      final Directory dir = await _getCaptureDirectory();
      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list().toList();
        for (var entity in entities) {
          if (entity is File && entity.path.toLowerCase().endsWith('.png')) {
            await entity.delete();
          }
        }
        _capturedFiles.clear();
        debugPrint('🧹 [ScreenCaptureService]: Đã dọn dẹp sạch toàn bộ ảnh trong ${dir.path}!');
      }
    } catch (e) {
      debugPrint('⚠️ [Lỗi dọn sạch thư mục ảnh]: $e');
    }
  }
}