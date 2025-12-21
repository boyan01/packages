import 'dart:ffi' as ffi;
import 'src/windows_message.dart';
import 'src/window_proc_delegate_internal.dart' as internal;

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

final List<WindowProcDelegateCallback?> _delegates = [];

/// Register a WindowProc delegate.
///
/// The delegate will be called for each WindowProc message.
/// Returns an ID that can be used to unregister the delegate.
int registerWindowProcDelegate(WindowProcDelegateCallback delegate) {
  if (!internal.initialized) {
    internal.initialize(_delegates, _handleWindowProc);
  }

  _delegates.add(delegate);
  return _delegates.length - 1;
}

/// Unregister a WindowProc delegate by its ID.
void unregisterWindowProcDelegate(int id) {
  if (id >= 0 && id < _delegates.length) {
    _delegates[id] = null; // Replace with null
  }

  // If all delegates are removed, clear the native callback
  if (_delegates.every((d) => d == null)) {
    _cleanup();
  }
}

void _handleWindowProc(ffi.Pointer<WindowsMessage> message) {
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

void _cleanup() {
  internal.cleanup();
  _delegates.clear();
}
