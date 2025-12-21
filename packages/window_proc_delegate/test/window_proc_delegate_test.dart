import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:window_proc_delegate/window_proc_delegate.dart';

void main() {
  test('registerDelegate returns valid ID', () {
    final id = WindowProcDelegate.registerDelegate((
      hwnd,
      message,
      wParam,
      lParam,
      result,
    ) {
      return false;
    });
    expect(id, greaterThanOrEqualTo(0));
  });

  test('unregisterDelegate removes delegate', () {
    final id = WindowProcDelegate.registerDelegate((
      hwnd,
      message,
      wParam,
      lParam,
      result,
    ) {
      return false;
    });
    expect(() => WindowProcDelegate.unregisterDelegate(id), returnsNormally);
  });
}
