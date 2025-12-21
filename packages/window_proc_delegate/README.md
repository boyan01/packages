# window_proc_delegate

A Flutter plugin that allows you to hook into Windows WindowProc messages from Dart code.

## Features

- Register WindowProc delegates from Dart
- Intercept and handle Windows messages (WM_* messages)
- Multiple delegates support with priority handling
- Clean API for registering and unregistering delegates

## Platform Support

| Platform | Supported |
|----------|-----------|
| Windows  | ✅        |
| Linux    | ❌        |
| macOS    | ❌        |
| Android  | ❌        |
| iOS      | ❌        |

## Getting Started

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  window_proc_delegate:
```

## Usage

### Basic Example

```dart
import 'package:window_proc_delegate/window_proc_delegate.dart';

// Register a delegate to handle WindowProc messages
int delegateId = WindowProcDelegate.registerDelegate(
  (int hwnd, int message, int wParam, int lParam) {
    // Check for WM_ACTIVATEAPP (0x001C)
    if (message == 0x001C) {
      print('Window activation changed: $wParam');
    }
    
    // Return null to let other delegates process the message
    return null;
  },
);

// Later, unregister the delegate
WindowProcDelegate.unregisterDelegate(delegateId);
```

### Intercepting Messages

You can intercept and prevent default handling of messages by returning a result value:

```dart
int delegateId = WindowProcDelegate.registerDelegate(
  (int hwnd, int message, int wParam, int lParam) {
    // Intercept WM_CLOSE (0x0010) to prevent window closing
    if (message == 0x0010) {
      print('Window close prevented!');
      return 0; // Return a result to handle the message
    }
    
    return null; // Let other delegates process the message
  },
);
```

### Setting Custom Result Values

You can set a custom result value for handled messages:

```dart
int delegateId = WindowProcDelegate.registerDelegate(
  (int hwnd, int message, int wParam, int lParam) {
    if (message == 0x0084) { // WM_NCHITTEST
      // Return custom result
      return 2; // HTCAPTION - makes the window draggable
    }
    
    return null;
  },
);
```

### Callback Parameters

The callback receives the following parameters:

- `hwnd` (int): Handle to the window
- `message` (int): The message identifier (WM_* constant)
- `wParam` (int): Additional message-specific information
- `lParam` (int): Additional message-specific information

**Return value:**
- Return an `int` value to handle the message and use that as the result
- Return `null` to let other delegates process the message

## Common Windows Messages

Here are some commonly used Windows messages:

| Message | Value | Description |
|---------|-------|-------------|
| WM_CLOSE | 0x0010 | Window is being closed |
| WM_ACTIVATEAPP | 0x001C | Window activation state changed |
| WM_NCHITTEST | 0x0084 | Hit test (for custom window dragging) |
| WM_SYSCOMMAND | 0x0112 | System command |
| WM_SIZE | 0x0005 | Window size changed |
| WM_MOVE | 0x0003 | Window position changed |

For a complete list, see the [Windows Message documentation](https://learn.microsoft.com/en-us/windows/win32/winmsg/about-messages-and-message-queues).

## Implementation Details

This plugin uses FFI (Foreign Function Interface) to communicate between Dart and native Windows code. It uses `NativeCallable.isolateLocal` to register Dart callbacks that can be called from native code.

The plugin maintains a list of delegates in Dart and dispatches WindowProc messages to each delegate in order until one handles the message (returns `true`).

## Example App

See the [example](example/) directory for a complete example application that demonstrates:
- Registering WindowProc delegates
- Logging received messages
- Intercepting specific messages

## Getting Started

This project is a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Windows.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

