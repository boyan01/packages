import 'dart:ffi' as ffi;

/// Windows message structure passed from native code
final class WindowsMessage extends ffi.Struct {
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
