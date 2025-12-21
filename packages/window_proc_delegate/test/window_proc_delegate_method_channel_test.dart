import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_proc_delegate/window_proc_delegate_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelWindowProcDelegate platform = MethodChannelWindowProcDelegate();
  const MethodChannel channel = MethodChannel('window_proc_delegate');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
