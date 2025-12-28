## 0.0.3
* Fix crash on multi engine

## 0.0.2
* Removed engine-specific message restriction - messages are now delivered to all registered delegates
* Fixed crash issue when unregistering delegates

## 0.0.1

* Initial release with WindowProc delegate support for Windows
* Features:
  - Register WindowProc delegates from Dart
  - Intercept and handle Windows messages (WM_* messages)
  - Multiple delegates support with priority handling
  - Clean API for registering and unregistering delegates

