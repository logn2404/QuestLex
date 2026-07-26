import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
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

  // Mã hóa PNG và ghi ra file hoàn toàn ở Background Thread
  final pngBytes = img.encodePng(image);
  final File newFile = File(filePath);
  await newFile.writeAsBytes(pngBytes);
}

class ScreenCaptureService {
  Directory? _customCaptureDir;
  final List<File> _capturedFiles = [];
  static const int _maxKeepCount = 10;

  Future<Directory> _getCaptureDirectory() async {
    if (_customCaptureDir != null && await _customCaptureDir!.exists()) {
      return _customCaptureDir!;
    }
    final Directory appDocDir = await getApplicationSupportDirectory();
    final Directory captureDir = Directory('${appDocDir.path}/questlex_captures');

    if (!await captureDir.exists()) {
      await captureDir.create(recursive: true);
      debugPrint('📂 [ScreenCaptureService]: Đã tạo thư mục ảnh: ${captureDir.path}');
    }

    _customCaptureDir = captureDir;
    return captureDir;
  }

  Future<bool> checkPermission() async {
    return true;
  }

  /// 🚀 Chụp màn hình bằng Win32 GDI + Mã hóa Isolate Background
  Future<String?> captureEntireScreen() async {
    try {
      final Directory saveDir = await _getCaptureDirectory();
      final String filePath = '${saveDir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.png';

      // 1. Lấy kích thước màn hình
      final hdcScreen = GetDC(0);
      final width = GetSystemMetrics(SM_CXSCREEN);
      final height = GetSystemMetrics(SM_CYSCREEN);

      // 2. Tạo Device Context & Bitmap
      final hdcMem = CreateCompatibleDC(hdcScreen);
      final hBitmap = CreateCompatibleBitmap(hdcScreen, width, height);
      final hOld = SelectObject(hdcMem, hBitmap);

      // 3. BitBlt lấy Pixel
      BitBlt(hdcMem, 0, 0, width, height, hdcScreen, 0, 0, SRCCOPY);

      // 4. Trích xuất dữ liệu thô (Raw Pixel Buffer)
      final bmi = calloc<BITMAPINFO>();
      bmi.ref.bmiHeader.biSize = sizeOf<BITMAPINFOHEADER>();
      bmi.ref.bmiHeader.biWidth = width;
      bmi.ref.bmiHeader.biHeight = -height;
      bmi.ref.bmiHeader.biPlanes = 1;
      bmi.ref.bmiHeader.biBitCount = 32;
      bmi.ref.bmiHeader.biCompression = BI_RGB;

      final pixelBuffer = calloc<Uint8>(width * height * 4);
      GetDIBits(hdcMem, hBitmap, 0, height, pixelBuffer, bmi, DIB_RGB_COLORS);

      // Copy nhanh dữ liệu thô sang Dart Memory trước khi free C++ Memory
      final Uint8List rawBytes = Uint8List.fromList(pixelBuffer.asTypedList(width * height * 4));

      // 5. Dọn dẹp Win32 Memory NGAY LẬP TỨC (Dưới 1ms)
      free(bmi);
      free(pixelBuffer);
      SelectObject(hdcMem, hOld);
      DeleteObject(hBitmap);
      DeleteDC(hdcMem);
      ReleaseDC(0, hdcScreen);

      // ⚡ 6. ĐẨY NẶNG SANG BACKGROUND ISOLATE MÃ HÓA & LƯU FILE
      await compute(_encodeAndSavePngInBackground, {
        'width': width,
        'height': height,
        'bytes': rawBytes,
        'filePath': filePath,
      });

      final File newFile = File(filePath);
      if (await newFile.exists()) {
        _capturedFiles.add(newFile);
        debugPrint('📸 [Chụp Isolate Mượt Mà]: ${newFile.path}');
        await _cleanOldCaptures();
      }

      return filePath;
    } catch (e) {
      debugPrint('❌ [Win32 Isolate Capture Error]: $e');
      return null;
    }
  }

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

  /// 🧹 Hàm xóa sạch TOÀN BỘ file ảnh trong thư mục capture khi bắt đầu phiên quét mới
  Future<void> clearAllCaptures() async {
    try {
      final Directory dir = await _getCaptureDirectory();
      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list().toList();
        for (var entity in entities) {
          if (entity is File && entity.path.endsWith('.png')) {
            await entity.delete();
          }
        }
        _capturedFiles.clear(); // Clear luôn danh sách quản lý RAM
        debugPrint('🧹 [ScreenCaptureService]: Đã dọn dẹp sạch toàn bộ ảnh trong thư mục!');
      }
    } catch (e) {
      debugPrint('⚠️ [Lỗi dọn sạch thư mục ảnh]: $e');
    }
  }

}