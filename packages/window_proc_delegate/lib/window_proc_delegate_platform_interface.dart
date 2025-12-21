import 'dart:ffi' as ffi;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'window_proc_delegate_method_channel.dart';

abstract class WindowProcDelegatePlatform extends PlatformInterface {
  /// Constructs a WindowProcDelegatePlatform.
  WindowProcDelegatePlatform() : super(token: _token);

  static final Object _token = Object();

  static WindowProcDelegatePlatform _instance =
      MethodChannelWindowProcDelegate();

  /// The default instance of [WindowProcDelegatePlatform] to use.
  ///
  /// Defaults to [MethodChannelWindowProcDelegate].
  static WindowProcDelegatePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WindowProcDelegatePlatform] when
  /// they register themselves.
  static set instance(WindowProcDelegatePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Set the native callback for WindowProc messages
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
    throw UnimplementedError('setCallback() has not been implemented.');
  }
}
