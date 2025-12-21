import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'window_proc_delegate_platform_interface.dart';

/// Signature for a WindowProc delegate callback.
///
/// Returns true if the message was handled, false otherwise.
/// If handled, [result] will be used as the return value of the WindowProc.
typedef WindowProcDelegateCallback =
    bool Function(
      int hwnd,
      int message,
      int wParam,
      int lParam,
      ffi.Pointer<ffi.Int64> result,
    );

/// Native callback signature for FFI
typedef NativeWindowProcCallback =
    ffi.Int32 Function(
      ffi.IntPtr hwnd,
      ffi.Uint32 message,
      ffi.Uint64 wParam,
      ffi.Int64 lParam,
      ffi.Pointer<ffi.Int64> result,
    );

class WindowProcDelegate {
  static final List<WindowProcDelegateCallback?> _delegates = [];
  static ffi.NativeCallable<NativeWindowProcCallback>? _nativeCallable;
  static bool _initialized = false;

  /// Register a WindowProc delegate.
  ///
  /// The delegate will be called for each WindowProc message.
  /// Returns an ID that can be used to unregister the delegate.
  static int registerDelegate(WindowProcDelegateCallback delegate) {
    if (!_initialized) {
      _initialize();
    }

    _delegates.add(delegate);
    return _delegates.length - 1;
  }

  /// Unregister a WindowProc delegate by its ID.
  static void unregisterDelegate(int id) {
    if (id >= 0 && id < _delegates.length) {
      _delegates[id] = null; // Replace with null
    }

    // If all delegates are removed, clear the native callback
    if (_delegates.every((d) => d == null)) {
      _cleanup();
    }
  }

  static void _initialize() {
    if (_initialized) return;

    // Create native callable that dispatches to all delegates
    _nativeCallable = ffi.NativeCallable<NativeWindowProcCallback>.isolateLocal(
      _handleWindowProc,
      exceptionalReturn: 0,
    );

    // Register the native callback with the plugin
    WindowProcDelegatePlatform.instance.setCallback(
      _nativeCallable!.nativeFunction,
    );
    _initialized = true;
  }

  static int _handleWindowProc(
    int hwnd,
    int message,
    int wParam,
    int lParam,
    ffi.Pointer<ffi.Int64> result,
  ) {
    // Call each delegate until one handles the message
    for (final delegate in _delegates) {
      if (delegate != null && delegate(hwnd, message, wParam, lParam, result)) {
        return 1; // Message handled
      }
    }
    return 0; // Message not handled
  }

  static void _cleanup() {
    if (_nativeCallable != null) {
      WindowProcDelegatePlatform.instance.setCallback(ffi.nullptr);
      _nativeCallable?.close();
      _nativeCallable = null;
      _initialized = false;
    }
    _delegates.clear();
  }

  Future<String?> getPlatformVersion() {
    return WindowProcDelegatePlatform.instance.getPlatformVersion();
  }
}
