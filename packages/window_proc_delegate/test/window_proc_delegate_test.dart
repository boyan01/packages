import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:window_proc_delegate/window_proc_delegate.dart';
import 'package:window_proc_delegate/window_proc_delegate_platform_interface.dart';
import 'package:window_proc_delegate/window_proc_delegate_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWindowProcDelegatePlatform
    with MockPlatformInterfaceMixin
    implements WindowProcDelegatePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final WindowProcDelegatePlatform initialPlatform =
      WindowProcDelegatePlatform.instance;

  test('$MethodChannelWindowProcDelegate is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWindowProcDelegate>());
  });

  test('getPlatformVersion', () async {
    WindowProcDelegate windowProcDelegatePlugin = WindowProcDelegate();
    MockWindowProcDelegatePlatform fakePlatform =
        MockWindowProcDelegatePlatform();
    WindowProcDelegatePlatform.instance = fakePlatform;

    expect(await windowProcDelegatePlugin.getPlatformVersion(), '42');
  });
}
