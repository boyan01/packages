import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Windows message structure passed from native code
final class WindowsMessage extends ffi.Struct {
  @ffi.Int64()
  external int viewId;

  @ffi.IntPtr()
  external int windowHandle;

  @ffi.Int32()
  external int message;

  @ffi.Int64()
  external int wParam;

  @ffi.Int64()
  external int lParam;

  @ffi.Int64()
  external int lResult;

  @ffi.Bool()
  external bool handled;
}

/// Signature for a WindowProc delegate callback.
///
/// The callback receives the window message parameters:
/// - [hwnd]: Handle to the window
/// - [message]: The message identifier (WM_* constant)
/// - [wParam]: Additional message-specific information
/// - [lParam]: Additional message-specific information
///
/// Returns the result value if the message was handled, or null to let other
/// delegates process the message.
typedef WindowProcDelegateCallback =
    int? Function(int hwnd, int message, int wParam, int lParam);

/// Native callback signature for FFI
typedef NativeWindowProcCallback =
    ffi.Void Function(ffi.Pointer<WindowsMessage> message);

/// Initialize Dart API DL
@ffi.Native<ffi.IntPtr Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'WindowProcDelegateInitDartApi',
)
external int _initDartApi(ffi.Pointer<ffi.Void> data);

/// Set the native callback for WindowProc messages
@ffi.Native<
  ffi.Void Function(
    ffi.Pointer<
      ffi.NativeFunction<ffi.Void Function(ffi.Pointer<WindowsMessage>)>
    >,
  )
>(symbol: 'WindowProcDelegateSetCallback')
external void _setCallback(
  ffi.Pointer<
    ffi.NativeFunction<ffi.Void Function(ffi.Pointer<WindowsMessage>)>
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
    );

    // Register the native callback with the plugin
    try {
      _setCallback(_nativeCallable!.nativeFunction);
    } catch (e) {
      debugPrint('Failed to set callback: $e');
    }
    _initialized = true;
  }

  static void _handleWindowProc(ffi.Pointer<WindowsMessage> message) {
    final msg = message.ref;

    // Call each delegate until one handles the message
    for (final delegate in _delegates) {
      if (delegate != null) {
        final result = delegate(
          msg.windowHandle,
          msg.message,
          msg.wParam,
          msg.lParam,
        );
        // If any delegate returns a non-null result, the message is handled
        if (result != null) {
          msg.lResult = result;
          msg.handled = true;
          return;
        }
      }
    }
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
