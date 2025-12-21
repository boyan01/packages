import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'window_proc_delegate_platform_interface.dart';

/// Native function signature for initializing Dart API DL
typedef NativeInitDartApiFunc = ffi.IntPtr Function(ffi.Pointer<ffi.Void>);
typedef DartInitDartApiFunc = int Function(ffi.Pointer<ffi.Void>);

/// Native function signature for setting the callback
typedef NativeSetCallbackFunc =
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
    );
typedef DartSetCallbackFunc =
    void Function(
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
    );

/// An implementation of [WindowProcDelegatePlatform] that uses method channels.
class MethodChannelWindowProcDelegate extends WindowProcDelegatePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('window_proc_delegate');

  static ffi.DynamicLibrary? _dylib;
  static DartSetCallbackFunc? _setCallbackFunc;
  static DartInitDartApiFunc? _initDartApiFunc;
  static bool _dartApiInitialized = false;

  static void _ensureInitialized() {
    if (_dylib != null) return;

    if (Platform.isWindows) {
      try {
        _dylib = ffi.DynamicLibrary.open('window_proc_delegate_plugin.dll');

        // Initialize Dart API DL
        _initDartApiFunc = _dylib!
            .lookup<ffi.NativeFunction<NativeInitDartApiFunc>>(
              'WindowProcDelegateInitDartApi',
            )
            .asFunction();

        if (!_dartApiInitialized) {
          final initResult = _initDartApiFunc!(
            ffi.NativeApi.initializeApiDLData,
          );
          if (initResult != 0) {
            debugPrint('Failed to initialize Dart API DL: $initResult');
          } else {
            _dartApiInitialized = true;
          }
        }

        _setCallbackFunc = _dylib!
            .lookup<ffi.NativeFunction<NativeSetCallbackFunc>>(
              'WindowProcDelegateSetCallback',
            )
            .asFunction();
      } catch (e) {
        debugPrint('Failed to load window_proc_delegate_plugin.dll: $e');
      }
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  void setCallback(
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
  ) {
    if (!Platform.isWindows) {
      return;
    }

    _ensureInitialized();

    if (_setCallbackFunc != null) {
      _setCallbackFunc!(callback);
    } else {
      debugPrint('WindowProcDelegateSetCallback function not found');
    }
  }
}
