import 'package:flutter/material.dart';

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
  int? _delegateId;
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _registerDelegate();
  }

  @override
  void dispose() {
    if (_delegateId != null) {
      unregisterWindowProcDelegate(_delegateId!);
    }
    super.dispose();
  }

  // Register a WindowProc delegate to intercept messages
  void _registerDelegate() {
    _delegateId = registerWindowProcDelegate((hwnd, message, wParam, lParam) {
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
      //   return 0; // Return a value to handle the message
      // }

      // Return null to let other handlers process the message
      return null;
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
