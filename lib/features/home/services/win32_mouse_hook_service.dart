import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';

// --- NATIVE HOOK GLOBAL VARIABLES ---
int _hMouseHook = 0;
Win32MouseHookService? _activeHookInstance;

DateTime? _lastClickTime;
const Duration _clickCooldown = Duration(milliseconds: 500);

int _mouseProc(int nCode, int wParam, int lParam) {
  try {
    if (nCode >= 0 && _activeHookInstance != null) {
      final service = _activeHookInstance!;
      
      // Chỉ xử lý nếu đang bật Hook và hệ thống không bận chụp
      if (service.isActive && !service.isBusy) {
        
        // 1. WM_LBUTTONDOWN - Click chuột trái
        if (wParam == WM_LBUTTONDOWN) {
          final now = DateTime.now();
          if (_lastClickTime == null || now.difference(_lastClickTime!) >= _clickCooldown) {
            _lastClickTime = now;

            Future.microtask(() {
              if (_activeHookInstance != null && _activeHookInstance!.isActive) {
                service.onClick?.call();
              }
            });
          }
        } 
        // 2. WM_MOUSEWHEEL - Cuộn chuột
        else if (wParam == WM_MOUSEWHEEL) {
          final mouseStruct = Pointer<MSLLHOOKSTRUCT>.fromAddress(lParam).ref;
          int mouseData = mouseStruct.mouseData;
          int wheelDelta = (mouseData >> 16) & 0xFFFF;
          if (wheelDelta >= 0x8000) wheelDelta -= 0x10000;

          Future.microtask(() {
            if (_activeHookInstance != null && _activeHookInstance!.isActive) {
              service.onScroll?.call(wheelDelta.toDouble());
            }
          });
        }
      }
    }
  } catch (e) {
    debugPrint('⚠️ [MouseProc Catch]: $e');
  }

  return CallNextHookEx(_hMouseHook, nCode, wParam, lParam);
}

class Win32MouseHookService {
  bool isActive = false;
  bool isBusy = false;

  VoidCallback? onClick;
  void Function(double delta)? onScroll;

  void start() {
    if (!Platform.isWindows || _hMouseHook != 0) return;
    try {
      _activeHookInstance = this;
      final mouseProcPointer = Pointer.fromFunction<HOOKPROC>(_mouseProc, 0);
      _hMouseHook = SetWindowsHookEx(
        WH_MOUSE_LL,
        mouseProcPointer,
        GetModuleHandle(nullptr),
        0,
      );
      debugPrint('🖱️ [Native Win32 Hook]: Đã kích hoạt Hook thành công.');
    } catch (e) {
      debugPrint('❌ [Mouse Hook Error]: $e');
    }
  }

  void stop() {
    if (!Platform.isWindows || _hMouseHook == 0) return;
    try {
      UnhookWindowsHookEx(_hMouseHook);
      _hMouseHook = 0;
      _activeHookInstance = null;
      debugPrint('🛑 [Native Win32 Hook]: Đã gỡ bỏ Hook.');
    } catch (e) {
      debugPrint('❌ [Mouse Hook Stop Error]: $e');
    }
  }
}