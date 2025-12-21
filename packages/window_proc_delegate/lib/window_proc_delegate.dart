import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter/foundation.dart';

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

/// Initialize Dart API DL
@ffi.Native<ffi.IntPtr Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'WindowProcDelegateInitDartApi',
)
external int _initDartApi(ffi.Pointer<ffi.Void> data);

/// Set the native callback for WindowProc messages
@ffi.Native<
  ffi.Void Function(
    ffi.Pointer<
      ffi.NativeFunction<
        ffi.Int32 Function(
          ffi.IntPtr,
          ffi.Uint32,
          ffi.Uint64,
          ffi.Int64,
          ffi.Pointer<ffi.Int64>,
        )
      >
    >,
  )
>(symbol: 'WindowProcDelegateSetCallback')
external void _setCallback(
  ffi.Pointer<
    ffi.NativeFunction<
      ffi.Int32 Function(
        ffi.IntPtr,
        ffi.Uint32,
        ffi.Uint64,
        ffi.Int64,
        ffi.Pointer<ffi.Int64>,
      )
    >
  >
  callback,
);

class WindowProcDelegate {
  static final List<WindowProcDelegateCallback?> _delegates = [];
  static ffi.NativeCallable<NativeWindowProcCallback>? _nativeCallable;
  static bool _initialized = false;
  static bool _dartApiInitialized = false;

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

  static void _ensureNativeLibraryInitialized() {
    if (_dartApiInitialized) return;

    if (!Platform.isWindows) return;

    try {
      final initResult = _initDartApi(ffi.NativeApi.initializeApiDLData);
      if (initResult != 0) {
        debugPrint('Failed to initialize Dart API DL: $initResult');
      } else {
        _dartApiInitialized = true;
      }
    } catch (e) {
      debugPrint('Failed to initialize Dart API: $e');
    }
  }

  static void _initialize() {
    if (_initialized) return;

    if (!Platform.isWindows) return;

    _ensureNativeLibraryInitialized();

    // Create native callable that dispatches to all delegates
    _nativeCallable = ffi.NativeCallable<NativeWindowProcCallback>.isolateLocal(
      _handleWindowProc,
      exceptionalReturn: 0,
    );

    // Register the native callback with the plugin
    try {
      _setCallback(_nativeCallable!.nativeFunction);
    } catch (e) {
      debugPrint('Failed to set callback: $e');
    }
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
      try {
        _setCallback(ffi.nullptr);
      } catch (e) {
        debugPrint('Failed to clear callback: $e');
      }
      _nativeCallable?.close();
      _nativeCallable = null;
      _initialized = false;
    }
    _delegates.clear();
  }
}
