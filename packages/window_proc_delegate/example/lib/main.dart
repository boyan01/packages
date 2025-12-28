import 'package:flutter/material.dart';

import 'package:window_proc_delegate/window_proc_delegate.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

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
    // Removed auto-registration - use buttons to register/unregister
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
    if (_delegateId != null) {
      // Already registered
      return;
    }

    final id = registerWindowProcDelegate((hwnd, message, wParam, lParam) {
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

    setState(() {
      _delegateId = id;
      _messages.insert(0, 'Delegate registered with ID: $id');
      if (_messages.length > 10) {
        _messages.removeLast();
      }
    });
  }

  // Unregister the WindowProc delegate
  void _unregisterDelegate() {
    if (_delegateId != null) {
      unregisterWindowProcDelegate(_delegateId!);
      setState(() {
        _messages.insert(0, 'Delegate unregistered (ID: $_delegateId)');
        _delegateId = null;
        if (_messages.length > 10) {
          _messages.removeLast();
        }
      });
    }
  }

  void _createChildWindow() async {
    await WindowController.create(
      WindowConfiguration(hiddenAtLaunch: false, arguments: ''),
    );
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
              // Control buttons
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _delegateId == null ? _registerDelegate : null,
                    child: const Text('Register Delegate'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _delegateId != null ? _unregisterDelegate : null,
                    child: const Text('Unregister Delegate'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _createChildWindow,
                    child: const Text('Create Child Window'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${_delegateId != null ? "Registered (ID: $_delegateId)" : "Not Registered"}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _delegateId != null ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
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
                          'No messages intercepted yet.\nRegister the delegate and try switching to another window and back.',
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
