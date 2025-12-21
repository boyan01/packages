import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'windows_message.dart';
import '../window_proc_delegate.dart';

/// Native callback signature for FFI
typedef NativeWindowProcCallback =
    ffi.Void Function(ffi.Pointer<WindowsMessage> message);

/// Initialize Dart API DL
@ffi.Native<ffi.IntPtr Function(ffi.Pointer<ffi.Void>)>(
  symbol: 'WindowProcDelegateInitDartApi',
)
external int initDartApi(ffi.Pointer<ffi.Void> data);

/// Set the native callback for WindowProc messages with engine ID
@ffi.Native<
  ffi.Void Function(
    ffi.Int64,
    ffi.Pointer<
      ffi.NativeFunction<ffi.Void Function(ffi.Pointer<WindowsMessage>)>
    >,
  )
>(symbol: 'WindowProcDelegateSetCallback')
external void setCallback(
  int engineId,
  ffi.Pointer<
    ffi.NativeFunction<ffi.Void Function(ffi.Pointer<WindowsMessage>)>
  >
  callback,
);

final MethodChannel channel = const MethodChannel('window_proc_delegate');

ffi.NativeCallable<NativeWindowProcCallback>? nativeCallable;
bool initialized = false;
bool dartApiInitialized = false;

void ensureNativeLibraryInitialized() {
  if (dartApiInitialized) return;

  if (!Platform.isWindows) return;

  try {
    final initResult = initDartApi(ffi.NativeApi.initializeApiDLData);
    if (initResult != 0) {
      debugPrint('Failed to initialize Dart API DL: $initResult');
    } else {
      dartApiInitialized = true;
    }
  } catch (e) {
    debugPrint('Failed to initialize Dart API: $e');
  }
}

void initialize(
  List<WindowProcDelegateCallback?> delegates,
  void Function(ffi.Pointer<WindowsMessage>) handleWindowProc,
) {
  if (initialized) return;

  if (!Platform.isWindows) return;

  ensureNativeLibraryInitialized();

  // Create native callable that dispatches to all delegates
  nativeCallable = ffi.NativeCallable<NativeWindowProcCallback>.isolateLocal(
    handleWindowProc,
  );

  // Get the engine ID and register the native callback
  try {
    final engineId = PlatformDispatcher.instance.engineId!;
    setCallback(engineId, nativeCallable!.nativeFunction);
    // Also notify the plugin instance via method channel
    channel.invokeMethod('setEngineId', {'engineId': engineId});
  } catch (e) {
    debugPrint('Failed to set callback: $e');
  }
  initialized = true;
}

void cleanup() {
  if (nativeCallable != null) {
    try {
      final engineId = PlatformDispatcher.instance.implicitView?.viewId ?? 0;
      setCallback(engineId, ffi.nullptr);
      channel.invokeMethod('setEngineId', {'engineId': 0});
    } catch (e) {
      debugPrint('Failed to clear callback: $e');
    }
    nativeCallable?.close();
    nativeCallable = null;
    initialized = false;
  }
}
