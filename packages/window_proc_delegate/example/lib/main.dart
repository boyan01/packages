import 'dart:ffi' as ffi;
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:window_proc_delegate/window_proc_delegate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _windowProcDelegatePlugin = WindowProcDelegate();
  int? _delegateId;
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _registerDelegate();
  }

  @override
  void dispose() {
    if (_delegateId != null) {
      WindowProcDelegate.unregisterDelegate(_delegateId!);
    }
    super.dispose();
  }

  // Register a WindowProc delegate to intercept messages
  void _registerDelegate() {
    _delegateId = WindowProcDelegate.registerDelegate((
      int hwnd,
      int message,
      int wParam,
      int lParam,
      ffi.Pointer<ffi.Int64> result,
    ) {
      // Example: Log WM_ACTIVATEAPP (0x001C) messages
      if (message == 0x001C) {
        setState(() {
          _messages.insert(0, 'WM_ACTIVATEAPP received: wParam=$wParam');
          if (_messages.length > 10) {
            _messages.removeLast();
          }
        });
      }

      // Example: Intercept WM_CLOSE (0x0010) - uncomment to prevent window closing
      // if (message == 0x0010) {
      //   setState(() {
      //     _messages.insert(0, 'WM_CLOSE intercepted!');
      //   });
      //   return true; // Return true to prevent default handling
      // }

      return false; // Let other handlers process the message
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion = 'N/A';

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('WindowProc Delegate Example')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Running on: $_platformVersion\n',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'WindowProc Messages:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages intercepted yet.\nTry switching to another window and back.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(_messages[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
