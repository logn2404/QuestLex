import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:win32/win32.dart';

import 'ai_service.dart';

int _hKeyboardHook = 0;
ScreenCaptureService? _activeCaptureService;
Pointer<NativeFunction<HOOKPROC>>? _keyboardProcPointer;
bool _shortcutKeyDown = false;
bool _controlKeyDown = false;
bool _shiftKeyDown = false;
Timer? _shortcutPollTimer;
DateTime? _lastShortcutTrigger;

int _keyboardProc(int nCode, int wParam, int lParam) {
  try {
    final service = _activeCaptureService;
    if (nCode >= 0 && service != null) {
      final isKeyDown = wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN;
      final isKeyUp = wParam == WM_KEYUP || wParam == WM_SYSKEYUP;
      final keyCode = Pointer<KBDLLHOOKSTRUCT>.fromAddress(lParam).ref.vkCode;
      final isControlKey = keyCode == 0x11 || keyCode == 0xA2 || keyCode == 0xA3;
      final isShiftKey = keyCode == 0x10 || keyCode == 0xA0 || keyCode == 0xA1;
        final controlPressed =
          _controlKeyDown || (GetAsyncKeyState(0x11) & 0x8000) != 0;
        final shiftPressed =
          _shiftKeyDown || (GetAsyncKeyState(0x10) & 0x8000) != 0;

      if (isControlKey) {
        _controlKeyDown = isKeyDown || (!isKeyUp && _controlKeyDown);
      } else if (isShiftKey) {
        _shiftKeyDown = isKeyDown || (!isKeyUp && _shiftKeyDown);
      } else if (isKeyUp && keyCode == 0x53) {
        _shortcutKeyDown = false;
      } else if (isKeyDown &&
          keyCode == 0x53 &&
          controlPressed &&
          shiftPressed &&
          !_shortcutKeyDown) {
        _shortcutKeyDown = true;
        debugPrint('⌨️ [Shortcut]: Nhận Ctrl+Shift+S, bắt đầu chụp.');
        Future.microtask(() {
          if (_activeCaptureService == service) {
            service.captureFromShortcut();
          }
        });
      }
    }
  } catch (e) {
    debugPrint('⚠️ [KeyboardProc Catch]: $e');
  }

  return CallNextHookEx(_hKeyboardHook, nCode, wParam, lParam);
}

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
  bool _isManualCaptureBusy = false;

  void startShortcutListener() {
    if (!Platform.isWindows || _hKeyboardHook != 0) return;

    try {
      _activeCaptureService = this;
      _keyboardProcPointer = Pointer.fromFunction<HOOKPROC>(_keyboardProc, 0);
      _hKeyboardHook = SetWindowsHookEx(
        WH_KEYBOARD_LL,
        _keyboardProcPointer!,
        GetModuleHandle(nullptr),
        0,
      );

      if (_hKeyboardHook == 0) {
        _activeCaptureService = null;
        debugPrint('⚠️ [Native Win32 Keyboard Hook]: Không thể kích hoạt, dùng polling shortcut.');
      } else {
        debugPrint('⌨️ [Native Win32 Keyboard Hook]: Đã kích hoạt Ctrl+Shift+S.');
      }

      _shortcutPollTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => _pollShortcutState(),
      );
      const hotkeyChannel = MethodChannel('questlex/screen_capture');
      hotkeyChannel.setMethodCallHandler((call) async {
        if (call.method == 'manualCaptureShortcut') {
          debugPrint('⌨️ [WM_HOTKEY]: Nhận Ctrl+Shift+S từ Windows runner.');
          _requestShortcutCapture();
        }
      });
    } catch (e) {
      _activeCaptureService = null;
      debugPrint('❌ [Keyboard Hook Error]: $e');
    }
  }

  void stopShortcutListener() {
    if (!Platform.isWindows) return;

    try {
      if (_hKeyboardHook != 0) {
        UnhookWindowsHookEx(_hKeyboardHook);
        _hKeyboardHook = 0;
      }
      _shortcutPollTimer?.cancel();
      _shortcutPollTimer = null;
      _activeCaptureService = null;
      _keyboardProcPointer = null;
      _shortcutKeyDown = false;
      _controlKeyDown = false;
      _shiftKeyDown = false;
      _lastShortcutTrigger = null;
      debugPrint('🛑 [Native Win32 Keyboard Hook]: Đã gỡ shortcut listener.');
    } catch (e) {
      debugPrint('❌ [Keyboard Hook Stop Error]: $e');
    }
  }

  void _pollShortcutState() {
    final controlPressed = (GetAsyncKeyState(0x11) & 0x8000) != 0;
    final shiftPressed = (GetAsyncKeyState(0x10) & 0x8000) != 0;
    final shortcutPressed =
        controlPressed && shiftPressed && (GetAsyncKeyState(0x53) & 0x8000) != 0;

    if (shortcutPressed && !_shortcutKeyDown) {
      _shortcutKeyDown = true;
      debugPrint('⌨️ [Shortcut Poll]: Nhận Ctrl+Shift+S, bắt đầu chụp.');
      _requestShortcutCapture();
    } else if (!shortcutPressed) {
      _shortcutKeyDown = false;
    }
  }

  void _requestShortcutCapture() {
    final now = DateTime.now();
    if (_lastShortcutTrigger != null &&
        now.difference(_lastShortcutTrigger!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastShortcutTrigger = now;
    captureFromShortcut();
  }

  void captureFromShortcut() {
    if (_isManualCaptureBusy) {
      debugPrint('⚠️ [Manual Capture]: Đang có lần chụp khác, bỏ qua shortcut.');
      return;
    }
    debugPrint('📷 [Manual Capture]: Đã nhận yêu cầu chụp từ shortcut.');
    _isManualCaptureBusy = true;
    unawaited(_captureAndProcessFromShortcut());
  }

  Future<void> _captureAndProcessFromShortcut() async {
    try {
      debugPrint('📷 [Manual Capture]: Bắt đầu captureEntireScreen().');
      final path = await captureEntireScreen();
      if (path == null) {
        debugPrint('❌ [Manual Capture]: Capture thất bại, không có đường dẫn file.');
        return;
      }

      debugPrint('✅ [Manual Capture]: Đã chụp và lưu file: $path');
      unawaited(_processManualCaptureInBackground());
    } catch (e, stackTrace) {
      debugPrint('❌ [Manual Capture Error]: $e\n$stackTrace');
    } finally {
      _isManualCaptureBusy = false;
    }
  }

  Future<void> _processManualCaptureInBackground() async {
    try {
      final result = await AIService.triggerScanFolder();
      if (result != null && result['success'] == true) {
        debugPrint('✅ [Manual AI Scan]: Backend đã xử lý ảnh chụp thủ công.');
      } else {
        debugPrint('⚠️ [Manual AI Scan]: Backend không xử lý được ảnh chụp.');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Manual AI Scan Error]: $e\n$stackTrace');
    }
  }

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
      debugPrint('📝 [Screen Capture]: File đích: $filePath');

      // 1. Lấy kích thước màn hình
      final hdcScreen = GetDC(0);
      final width = GetSystemMetrics(SM_CXSCREEN);
      final height = GetSystemMetrics(SM_CYSCREEN);
      debugPrint('🖥️ [Screen Capture]: Kích thước màn hình: ${width}x$height, HDC: $hdcScreen');

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
      debugPrint('🧩 [Screen Capture]: Đã lấy dữ liệu pixel, bắt đầu encode PNG.');

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
      debugPrint('🧩 [Screen Capture]: Encode và ghi PNG hoàn tất.');

      final File newFile = File(filePath);
      if (await newFile.exists()) {
        final fileSize = await newFile.length();
        debugPrint('✅ [Chụp & Lưu Thành Công]: ${newFile.path} ($fileSize bytes)');
      } else {
        debugPrint('❌ [Screen Capture]: File không tồn tại sau khi ghi: $filePath');
        return null;
      }

      return filePath;
    } catch (e) {
      debugPrint('❌ [Win32 Capture Error]: $e');
      return null;
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
        debugPrint('🧹 [ScreenCaptureService]: Đã dọn dẹp sạch toàn bộ ảnh trong ${dir.path}!');
      }
    } catch (e) {
      debugPrint('⚠️ [Lỗi dọn sạch thư mục ảnh]: $e');
    }
  }

  void dispose() {
    if (_activeCaptureService == this) {
      stopShortcutListener();
    }
  }
}